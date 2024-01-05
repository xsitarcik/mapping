from snakemake.utils import validate


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


### Layer for adapting other workflows  ###############################################################################


def get_fastq_for_mapping(wildcards):
    return reads_workflow.get_final_fastq_for_sample(wildcards.sample)


def get_read_group_for_sample(wildcards):
    return reads_workflow.get_read_group_for_sample(wildcards.sample)


def get_sample_names():
    return reads_workflow.get_sample_names()


### Data input handling independent of wildcards ######################################################################


def get_reference_dir():
    return config["mapping"]["reference_dir"]


def get_reference_name():
    return os.path.basename(os.path.realpath(get_reference_dir()))


def get_bwa_index_for_mapping():
    return multiext(
        os.path.join(get_reference_dir(), "bwa_index", get_reference_name()),
        ".amb",
        ".ann",
        ".bwt",
        ".pac",
        ".sa",
    )


def get_reference_fasta_path():
    return os.path.join(get_reference_dir(), f"{get_reference_name()}.fa")


def get_reference_faidx_path():
    return os.path.join(get_reference_dir(), f"{get_reference_name()}.fa.fai")


def get_reference_dict():
    return os.path.join(get_reference_dir(), f"{get_reference_name()}.dict")


### Contract for other workflows ######################################################################################


def get_final_bam_for_sample(sample: str):
    return f"results/mapping/deduplicated/{sample}.bam"


### Global rule-set stuff #############################################################################################


def get_outputs():
    sample_names = get_sample_names()
    return {
        "bams": expand("results/mapping/deduplicated/{sample}.bam", sample=sample_names),
        "qualimap": expand("results/mapping/deduplicated/{sample}/bamqc", sample=sample_names),
    }


### Resource handling #################################################################################################


def get_mem_mb_for_picard(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["picard_mem_mb"] * attempt)


def get_mem_mb_for_qualimap(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["qualimap_mem_mb"] * attempt)


def get_mem_mb_for_mapping(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["mapping_mem_mb"] * attempt)


def get_mem_mb_for_bam_index(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["bam_index_mem_mb"] * attempt)
