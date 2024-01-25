from snakemake.utils import validate


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


### Layer for adapting other workflows  ###############################################################################


def get_fastq_for_mapping(wildcards):
    return reads_workflow.get_final_fastq_for_sample(wildcards.sample)


def get_sample_names():
    return reads_workflow.get_sample_names()


### Data input handling independent of wildcards ######################################################################


def get_reference_name_from_path(path: str):
    return os.path.basename(os.path.realpath(path))


reference_dict = {get_reference_name_from_path(path): path for path in config["mapping"]["reference_dirs"]}


def get_reference_dir_for_name(name: str):
    return reference_dict[name]


### Global rule-set stuff #############################################################################################


def get_outputs():
    sample_names = get_sample_names()
    step = "deduplication" if config["mapping"]["deduplication"] else "mapping"

    outputs = {}
    outputs["bams"] = expand(
        f"results/mapping/{{reference}}/{step}/{{sample}}.bam", sample=sample_names, reference=reference_dict.keys()
    )

    if qualiap_steps := config["mapping"]["_generate_qualimap"]:
        outputs["qualimaps"] = expand(
            f"results/mapping/{{reference}}/{step}/{{sample}}/bamqc",
            sample=sample_names,
            step=qualimap_steps,
            reference=reference_dict.keys(),
        )

    return outputs


def infer_bwa_index_for_mapping(wildcards):
    return multiext(
        os.path.join(get_reference_dir_for_name(wildcards.reference), "bwa_index", wildcards.reference),
        ".amb",
        ".ann",
        ".bwt",
        ".pac",
        ".sa",
    )


### Resource handling #################################################################################################


def get_mem_mb_for_deduplication(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__deduplication_mem_mb"] * attempt)


def get_mem_mb_for_qualimap(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__qualimap_mem_mb"] * attempt)


def get_mem_mb_for_mapping(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__mapping_mem_mb"] * attempt)


def get_mem_mb_for_indexing(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping__indexing_mem_mb"] * attempt)
