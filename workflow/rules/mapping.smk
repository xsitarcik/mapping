rule samtools__index_reference:
    input:
        reference="{reference_dir}/{reference}.fa",
    output:
        protected("{reference_dir}/{reference}.fa.fai"),
    log:
        "{reference_dir}/logs/samtools__prepare_fai_index/{reference}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/samtools/faidx"


rule custom__infer_read_group:
    input:
        get_fastq_for_mapping,
    output:
        read_group="results/reads/.read_groups/{sample}.txt",
    params:
        sample_id=lambda wildcards: wildcards.sample,
    log:
        "logs/custom/infer_and_store_read_group/{sample}.log",
    localrule: True
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/custom/read_group"


rule picard__prepare_dict_index:
    input:
        "{reference_dir}/{reference}.fa",
    output:
        protected("{reference_dir}/{reference}.dict"),
    log:
        "{reference_dir}/logs/picard__prepare_dict_index/{reference}.log",
    params:
        extra="",
    resources:
        mem_mb=get_mem_mb_for_deduplication,
    wrapper:
        "v3.7.0/bio/picard/createsequencedictionary"


rule samtools__bam_index:
    input:
        bam="results/mapping/{reference}/mapping/{sample}.bam",
    output:
        bai="results/mapping/{reference}/mapping/{sample}.bam.bai",
    threads: min(config["threads"]["mapping__indexing"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_indexing,
    log:
        "logs/mapping/indexing/{reference}/mapped/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/samtools/index"


rule samtools__stats:
    input:
        bam=infer_final_bam,
        ref=infer_reference_fasta,
    output:
        "results/mapping/{reference}/{step}/{sample}.samtools_stats",
    params:
        extra=lambda wildcards, input: f"--ref-seq {input.ref}",
    threads: min(config["threads"]["mapping__indexing"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_indexing,
    log:
        "logs/mapping/samtools_stats/{reference}/{sample}_{step}.log",
    wrapper:
        "v3.9.0/bio/samtools/stats"
