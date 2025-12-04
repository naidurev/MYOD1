# MYOD1 Comparative Genomics Analysis

Comprehensive evolutionary and structural analysis of the MYOD1 (Myogenic Differentiation 1) protein across species.

## Overview

This repository contains a complete bioinformatics pipeline for analyzing the evolutionary conservation, phylogenetic relationships, and functional domains of the MYOD1 protein. MYOD1 is a master regulator transcription factor of the basic helix-loop-helix (bHLH) family that controls skeletal muscle differentiation.

### Key Features

- **BLAST-based homolog discovery** across 5000+ sequences
- **Ortholog identification** using OrthoFinder with DIAMOND
- **Multiple sequence alignment** using MAFFT and PRANK
- **Phylogenetic tree construction** with publication-ready visualizations
- **Domain analysis** using HMMER for bHLH and functional regions
- **Conservation analysis** with Shannon entropy-based scoring
- **Automated report generation** in multiple formats

## Project Structure

```
MYOD1/
└── blast_conservation/    # Main analysis directory
    ├── 01_sequences/          # Input sequences
    │   ├── query/            # MYOD1 query sequence
    │   └── homologs/         # Retrieved homolog sequences
    ├── 02_blast_results/      # BLAST search results
    │   ├── by_species/       # Organized by taxonomic groups
    │   ├── orthologs/        # Predicted orthologs
    │   ├── paralogs/         # Predicted paralogs
    │   └── statistics/       # Summary statistics
    ├── 03_alignments/         # Multiple sequence alignments
    │   ├── mafft/           # MAFFT alignments
    │   └── prank/           # PRANK alignments
    ├── 03_orthofinder/        # OrthoFinder analysis
    │   └── proteomes/        # Input proteomes
    ├── 04_phylogeny/          # Phylogenetic trees
    │   ├── mafft_trees/     # Trees from MAFFT alignments
    │   ├── prank_trees/     # Trees from PRANK alignments
    │   ├── publication_trees/ # Publication-ready figures
    │   └── visualizations/   # Tree visualizations
    └── 05_domains/            # Domain analysis
        ├── hmmer/           # HMMER domain predictions
        └── visualizations/   # Domain structure plots
```

## Prerequisites

### Required Software

- **BLAST+** (v2.10+) - Sequence similarity search
- **OrthoFinder** (v3.1.0+) - Ortholog identification
- **DIAMOND** - Fast sequence aligner
- **MAFFT** - Multiple sequence alignment
- **PRANK** - Phylogeny-aware sequence aligner
- **HMMER** (v3.3+) - Domain identification
- **Python** (v3.7+) - Analysis scripts
- **Node.js** - Report generation

### Python Dependencies

```bash
pip install biopython numpy matplotlib seaborn pandas
```

### Node.js Dependencies

```bash
npm install
```

## Quick Start

Navigate to the analysis directory:
```bash
cd blast_conservation
```

### 1. BLAST Search for Homologs

```bash
./run_phase2a_full.sh
```

Performs comprehensive BLAST search against RefSeq protein database:
- E-value threshold: 1e-5
- Max target sequences: 5000
- Filters: ≥25% identity, ≥30% query coverage
- Outputs best hit per species

**Output**: `02_blast_results/MYOD1_homologs_filtered.tsv`

### 2. Ortholog Identification

```bash
./run_orthofinder_v3.sh
```

Uses OrthoFinder with DIAMOND for fast ortholog detection:
- Identifies orthogroups
- Detects gene duplications
- Builds species trees

**Output**: `03_orthofinder/Results_*/Orthogroups/`

### 3. Multiple Sequence Alignment

```bash
./run_phase3_msa.sh
```

Performs alignments using two methods:
- **MAFFT**: Fast, accurate, suitable for large datasets
- **PRANK**: Phylogeny-aware, better for evolutionary studies

**Output**: `03_alignments/mafft/` and `03_alignments/prank/`

### 4. Phylogenetic Tree Construction

```bash
./run_phase4_trees.sh
```

Builds maximum likelihood phylogenetic trees:
- Uses RAxML or IQ-TREE
- Performs bootstrap analysis
- Generates tree visualizations

**Output**: `04_phylogeny/publication_trees/`

### 5. Domain Analysis (Part 1)

```bash
./run_phase5_part1.sh
```

Identifies conserved domains using HMMER:
- Searches Pfam database
- Identifies bHLH domain
- Maps functional sites

### 6. Conservation & Visualization (Part 2)

```bash
./run_phase5_part2.sh
```

Analyzes sequence conservation and generates visualizations:
- Calculates position-specific conservation scores
- Creates heatmaps and domain diagrams
- Generates final summary report

**Output**: `05_domains/visualizations/`

## Key Scripts

### Analysis Scripts

- `analyze_conservation_fixed.py` - Calculate Shannon entropy-based conservation scores
- `extract_domains_fixed.py` - Extract domain regions from alignments
- `visualize_domains_fixed.py` - Create domain structure visualizations
- `create_final_heatmaps.py` - Generate conservation heatmaps
- `create_trees_final.py` - Build phylogenetic trees
- `visualize_trees_publication.py` - Create publication-quality tree figures
- `generate_final_summary.py` - Create comprehensive analysis summary

### Workflow Scripts

- `run_phase2a_full.sh` - BLAST homolog search
- `run_orthofinder_v3.sh` - OrthoFinder ortholog identification
- `run_phase3_msa.sh` - Multiple sequence alignment
- `run_phase4_trees.sh` - Phylogenetic tree construction
- `run_phase5_part1.sh` - Domain identification
- `run_phase5_part2.sh` - Conservation analysis and visualization

### Report Generation

- `create_myod1_report.js` - Generate comprehensive analysis report
- `generate_myod1_report.js` - Report compilation script

## Input Files

- `MYOD1_human.fasta` - Human MYOD1 protein sequence (NCBI)
- `MYOD1_human_uniprot.fasta` - Human MYOD1 from UniProt
- `MYOD1_human.gb` - GenBank annotation
- `1MDY.pdb` - Crystal structure (if available)
- `MYOD1_info.txt` - Protein information summary
- `species_mapping.txt` - Taxonomic mappings
- `protein_name_mapping.txt` - Protein name standardization

## Output Files

### BLAST Results
- `MYOD1_homologs_annotated.tsv` - Full BLAST results with annotations
- `MYOD1_homologs_filtered.tsv` - High-quality hits only
- `MYOD1_homologs_unique_species.tsv` - Best hit per species
- `top100_accessions.txt` - Accessions for sequence retrieval

### Alignments
- `OG0000000_sequences.fasta` - Orthogroup sequences
- `OG0000000_aligned.fasta` - Aligned sequences
- `alignment_comparison.txt` - Alignment statistics

### Phylogenetic Trees
- `*.treefile` - Newick format phylogenetic trees
- `*.pdf` - Publication-ready tree figures
- `phylogeny_summary.txt` - Tree statistics and analysis

### Domain Analysis
- `*_domains.txt` - HMMER domain predictions
- `*_bHLH_conservation.txt` - bHLH domain conservation scores
- `*_parsed.json` - Structured domain annotations
- `domain_analysis_summary.txt` - Overall summary

### Visualizations
- Conservation heatmaps (PNG/PDF)
- Domain structure diagrams (PNG/PDF)
- Phylogenetic tree figures (PNG/PDF)

## MYOD1 Protein Information

**Function**: Master regulator of skeletal muscle differentiation

**Protein Family**: Basic helix-loop-helix (bHLH) transcription factors

**Key Domains**:
- **bHLH domain**: DNA binding and protein dimerization
- **TAD**: Transactivation domain for gene regulation

**Biological Process**:
- Muscle cell differentiation
- Myogenesis
- Transcription regulation

**Reference IDs**:
- NCBI: NP_002469.2
- UniProt: P15172
- Gene ID: 4654

## Interpretation Guide

### Conservation Scores
- **>0.9**: Highly conserved (functionally critical)
- **0.7-0.9**: Moderately conserved (functionally important)
- **<0.7**: Variable (possibly species-specific adaptations)

### BLAST Parameters
- **E-value**: Statistical significance of match (lower = better)
- **Identity**: Percentage of identical amino acids
- **Coverage**: Percentage of query sequence aligned
- **Bitscore**: Quality of alignment (higher = better)

### Domain Analysis
- **E-value < 1e-5**: High confidence domain prediction
- **bHLH domain**: Typically ~60 amino acids
- **Functional sites**: DNA contact residues, dimerization interfaces

## Citation

If you use this pipeline, please cite:

- **BLAST**: Altschul SF, et al. (1990) Basic local alignment search tool. J Mol Biol. 215:403-410
- **OrthoFinder**: Emms DM, Kelly S. (2019) OrthoFinder: phylogenetic orthology inference for comparative genomics. Genome Biol. 20:238
- **MAFFT**: Katoh K, Standley DM. (2013) MAFFT multiple sequence alignment software version 7. Mol Biol Evol. 30:772-780
- **PRANK**: Löytynoja A. (2014) Phylogeny-aware alignment with PRANK. Methods Mol Biol. 1079:155-170
- **HMMER**: Eddy SR. (2011) Accelerated profile HMM searches. PLoS Comput Biol. 7:e1002195

## License

This project is provided for academic and research purposes.

## Contact

For questions or issues, please open an issue in this repository.

## Acknowledgments

- RefSeq protein database (NCBI)
- UniProt protein database
- Pfam domain database
- PDB structural database
