
rule qualimap__mapping_quality_report:
    input:
        bam="results/mapping/{reference}/{step}/{sample}.bam",
        bai="results/mapping/{reference}/{step}/{sample}.bam.bai",
    output:
        report_dir=report(
            directory("results/mapping/{reference}/{step}/bamqc/{sample}"),
            category="Mapping QC for {reference}",
            labels={
                "Sample": "{sample}",
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
        "logs/qualimap/{reference}/{step}/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.13.4/wrappers/qualimap/bamqc"
