# MYOD1 ChIP-seq Analysis

Genome-wide identification of MYOD1 binding sites in mouse embryonic fibroblasts.

## Key Results

- **77,310 binding peaks** identified
- **62.9%** in promoter regions
- **88.6%** contain E-box motif (CANNTG)
- **14,566 target genes** annotated

## Directory Structure

- `06_peaks/` - MACS2 peak calling results
- `08_annotation/` - Gene annotations
- `09_chipseeker/` - Functional enrichment
- `09_motifs/` - Motif analysis  
- `presentation_chipseq_minimal/` - Figures

## Data Availability

Large files excluded from repository:
- Raw FASTQ: [NCBI SRA SRR396786](https://www.ncbi.nlm.nih.gov/sra/SRR396786), [SRR398262](https://www.ncbi.nlm.nih.gov/sra/SRR398262)
- BAM/BigWig files: Regenerable from raw data

Total repository size: ~30 MB
