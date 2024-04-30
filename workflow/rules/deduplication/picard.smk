rule picard__mark_duplicates:
    input:
        bams="results/mapping/{reference}/mapping/{sample}.bam",
        bai="results/mapping/{reference}/mapping/{sample}.bam.bai",
    output:
        bam="results/mapping/{reference}/deduplication/{sample}.bam",
        idx="results/mapping/{reference}/deduplication/{sample}.bam.bai",
        metrics="results/mapping/{reference}/deduplication/{sample}.stats",
    resources:
        mem_mb=get_mem_mb_for_deduplication,
    log:
        "logs/deduplication/picard/{reference}/{sample}.log",
    wrapper:
        "v3.9.0/bio/picard/markduplicates"
