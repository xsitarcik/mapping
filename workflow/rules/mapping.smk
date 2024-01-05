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
        mem_mb=get_mem_mb_for_picard,
    wrapper:
        "v2.13.0/bio/picard/createsequencedictionary"


rule bwa__build_index:
    input:
        "{reference_dir}/{fasta}.fa",
    output:
        idx=protected(multiext("{reference_dir}/bwa_index/{fasta}", ".amb", ".ann", ".bwt", ".pac", ".sa")),
    params:
        prefix=lambda wildcards, output: os.path.splitext(output.idx[0])[0],
        approach="bwtsw",
    log:
        "{reference_dir}/bwa_index/logs/{fasta}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/bwa/index"


rule bwa__map_reads_to_reference:
    input:
        reads=get_fastq_for_mapping,
        index=get_bwa_index_for_mapping(),
        read_group="results/reads/.read_groups/{sample}.txt",
    output:
        bam=temp("results/mapping/mapped/{sample}.bam"),
    threads: min(config["threads"]["mapping"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_mapping,
    log:
        "logs/bwa/map_reads_to_reference/{sample}.log",
    benchmark:
        "benchmarks/bwa/map_reads_to_reference/{sample}.benchmark"
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/bwa/map"


rule samtools__bam_index:
    input:
        bam="results/mapping/mapped/{sample}.bam",
    output:
        bai="results/mapping/mapped/{sample}.bam.bai",
    benchmark:
        "benchmarks/samtools/bam_index/mapped/{sample}.benchmark"
    threads: min(config["threads"]["bam_index"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_bam_index,
    log:
        "logs/samtools/bam_index/mapped/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/samtools/index"


rule picard__mark_duplicates:
    input:
        bams="results/mapping/mapped/{sample}.bam",
        bai="results/mapping/mapped/{sample}.bam.bai",
    output:
        bam="results/mapping/deduplicated/{sample}.bam",
        idx="results/mapping/deduplicated/{sample}.bam.bai",
        metrics=temp("results/mapping/deduplicated/{sample}.stats"),
    resources:
        mem_mb=get_mem_mb_for_picard,
    log:
        "logs/picard/mark_duplicates/{sample}.log",
    benchmark:
        "benchmarks/picard/mark_duplicates/{sample}.benchmark"
    wrapper:
        "v2.13.0/bio/picard/markduplicates"


rule qualimap__mapping_quality_report:
    input:
        bam="results/mapping/{step}/{sample}.bam",
        bai="results/mapping/{step}/{sample}.bam.bai",
    output:
        report_dir=report(
            directory("results/mapping/{step}/{sample}/bamqc"),
            category="{sample}",
            labels={
                "Type": "Qualimap for {step}",
            },
            htmlindex="qualimapReport.html",
        ),
    params:
        extra=[
            "--paint-chromosome-limits",
            "-outformat PDF:HTML",
        ],
    resources:
        mem_mb=get_mem_mb_for_qualimap,
    log:
        "logs/qualimap/mapping_quality_report/{step}/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/qualimap/bamqc"
