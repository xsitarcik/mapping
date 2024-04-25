from snakemake.utils import validate


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml", set_default=False)


### Layer for adapting other workflows  ###############################################################################


def get_fastq_for_mapping(wildcards):
    return reads_workflow.get_final_fastq_for_sample(wildcards.sample)


def get_sample_names():
    return reads_workflow.get_sample_names()


def get_multiqc_inputs_for_reads():
    return reads_workflow.get_multiqc_inputs()


### Data input handling independent of wildcards ######################################################################


def get_reference_name_from_path(path: str):
    name, ext = os.path.splitext(os.path.basename(os.path.realpath(path)))
    if ext not in [".fasta", ".fa"]:
        raise ValueError(f"Reference file {path} does not have a valid extension (.fasta or .fa)")
    return name


reference_dict = {
    get_reference_name_from_path(path): os.path.realpath(path) for path in config["mapping"]["reference_fasta_paths"]
}


def get_reference_dir_for_name(name: str):
    return os.path.dirname(reference_dict[name])


def get_reference_names():
    return reference_dict.keys()


# def sample_has_enough_mapped_reads(sample_name: str):
#     with checkpoints.checkpoint__min_mapped_reads_count.get(sample=sample_name).output[0].open() as f:
#         num = int(f.read().strip())
#     return num >= 1

### Global rule-set stuff #############################################################################################


def get_last_step():
    return "deduplication" if config["mapping"]["deduplication"] else "mapping"


def get_outputs():
    sample_names = get_sample_names()

    outputs = {}
    outputs["bams"] = expand(
        f"results/mapping/{{reference}}/{get_last_step()}/{{sample}}.bam",
        sample=sample_names,
        reference=get_reference_names(),
    )

    if qualimap_steps := config["mapping"]["_generate_qualimap"]:
        outputs["qualimaps"] = expand(
            "results/mapping/{reference}/{step}/bamqc/{sample}",
            sample=sample_names,
            step=qualimap_steps,
            reference=get_reference_names(),
        )

    return outputs


def get_standalone_outputs():
    # outputs that will be produced if the module is run as a standalone workflow, not as a part of a larger workflow
    return {
        "multiqc_report": "results/_aggregation/multiqc.html",
    }


def infer_bwa_index_for_mapping(wildcards):
    return multiext(
        os.path.join(get_reference_dir_for_name(wildcards.reference), "bwa_index", wildcards.reference),
        ".amb",
        ".ann",
        ".bwt",
        ".pac",
        ".sa",
    )


def infer_final_bam(wildcards):
    return get_input_bam_for_sample_and_ref(wildcards.sample, wildcards.reference)


def infer_final_bai(wildcards):
    return get_input_bai_for_sample_and_ref(wildcards.sample, wildcards.reference)


def infer_reference_fasta(wildcards):
    return reference_dict[wildcards.reference]


### Contract for other workflows ######################################################################################


def get_input_bam_for_sample_and_ref(sample: str, reference: str):
    return f"results/mapping/{reference}/{get_last_step()}/{sample}.bam"


def get_input_bai_for_sample_and_ref(sample: str, reference: str):
    return f"results/mapping/{reference}/{get_last_step()}/{sample}.bam.bai"


def get_multiqc_inputs():
    outs = get_multiqc_inputs_for_reads()

    if config["mapping"]["deduplication"] == "picard":
        outs["picard_dedup"] = expand(
            "results/mapping/{reference}/deduplication/{sample}.stats",
            sample=get_sample_names(),
            reference=get_reference_names(),
        )

    step = ""
    if "deduplication" in config["mapping"]["_generate_qualimap"]:
        step = "deduplication"
    elif "mapping" in config["mapping"]["_generate_qualimap"]:
        step = "mapping"
    if step:
        outs["qualimaps"] = expand(
            f"results/mapping/{{reference}}/{step}/bamqc/{{sample}}",
            sample=get_sample_names(),
            reference=get_reference_names(),
        )

    outs["samtools_stats"] = expand(
        "results/mapping/{reference}/{step}/{sample}.samtools_stats",
        step=get_last_step(),
        sample=get_sample_names(),
        reference=get_reference_names(),
    )
    return outs


### Parameter parsing from config #####################################################################################


### Resource handling #################################################################################################


def get_mem_mb_for_deduplication(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__deduplication_mem_mb"] * attempt)


def get_mem_mb_for_qualimap(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__qualimap_mem_mb"] * attempt)


def get_mem_mb_for_mapping(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__mapping_mem_mb"] * attempt)


def get_mem_mb_for_indexing(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__indexing_mem_mb"] * attempt)
