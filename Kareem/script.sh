#!/bin/bash

# List of sample names
samples=("ACBarrie" "Alsen" "Baxter" "Chara" "Drysdale")

# Reference genome URL
reference_url="https://raw.githubusercontent.com/josoga2/yt-dataset/main/dataset/raw_reads/reference.fasta"

# Download reference genome
wget -O reference.fasta $reference_url

# Loop through each sample
for sample in "${samples[@]}"; do
    echo "Processing $sample"

    # Download the forward and reverse reads
    wget -O ${sample}_R1.fastq.gz https://github.com/josoga2/yt-dataset/raw/main/dataset/raw_reads/${sample}_R1.fastq.gz
    wget -O ${sample}_R2.fastq.gz https://github.com/josoga2/yt-dataset/raw/main/dataset/raw_reads/${sample}_R2.fastq.gz

    # Run FastQC for quality control
    fastqc ${sample}_R1.fastq.gz ${sample}_R2.fastq.gz

    # Run FastP for trimming
    fastp -i ${sample}_R1.fastq.gz -I ${sample}_R2.fastq.gz -o ${sample}_R1_trimmed.fastq.gz -O ${sample}_R2_trimmed.fastq.gz

    # Run BWA for genome mapping
    bwa index reference.fasta
    bwa mem reference.fasta ${sample}_R1_trimmed.fastq.gz ${sample}_R2_trimmed.fastq.gz > ${sample}_aligned.sam

    # Convert SAM to BAM, sort, and index using Samtools
    samtools view -S -b ${sample}_aligned.sam > ${sample}_aligned.bam
    samtools sort ${sample}_aligned.bam -o ${sample}_sorted.bam
    samtools index ${sample}_sorted.bam

    # Run Bcftools for variant calling
    bcftools mpileup -f reference.fasta -d 500 ${sample}_sorted.bam | bcftools call -mv --ploidy 1 -Ov -o ${sample}_variants.vcf

    echo "$sample processing completed"
done
