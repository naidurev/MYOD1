#!/bin/bash
# ========================================
# Phase 5: Domain Analysis (HMMER + InterProScan)
# ========================================

set -e
set -o pipefail

# Colors for terminal output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 5: Domain Analysis (HMMER + InterProScan)${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Checking and installing required tools...${NC}\n"

# Ensure conda environment is active
if [ -z "$CONDA_DEFAULT_ENV" ]; then
    source ~/miniconda3/etc/profile.d/conda.sh
    conda activate orthology
fi

# ---- Install and verify dependencies ----
echo -e "${YELLOW}Installing HMMER and GSL...${NC}"
conda install -y -c bioconda hmmer
conda install -y -c conda-forge gsl

# ---- Fix GSL version mismatch if needed ----
if [ ! -f "$CONDA_PREFIX/lib/libgsl.so.25" ]; then
    if [ -f "$CONDA_PREFIX/lib/libgsl.so.27" ]; then
        echo -e "${YELLOW}Linking libgsl.so.27 → libgsl.so.25 (compatibility fix)${NC}"
        ln -sf "$CONDA_PREFIX/lib/libgsl.so.27" "$CONDA_PREFIX/lib/libgsl.so.25"
    fi
fi

# ---- Check InterProScan ----
if ! command -v interproscan &>/dev/null; then
    echo -e "${YELLOW}⚠ InterProScan not found${NC}"
    echo -e "You can install it with:\n  ${GREEN}conda install -c bioconda interproscan${NC}\n"
else
    echo -e "${GREEN}✓ InterProScan available${NC}"
fi

# ---- Fix analyze_conservation.py bug ----
if [ -f "analyze_conservation.py" ]; then
    if ! grep -q "^import os" analyze_conservation.py; then
        echo -e "${YELLOW}Patching analyze_conservation.py (adding missing import os)...${NC}"
        sed -i '1iimport os' analyze_conservation.py
    fi
fi

# ---- Pfam Database Setup ----
echo -e "${YELLOW}Setting up Pfam database...${NC}"
mkdir -p 05_domains/pfam_database
cd 05_domains/pfam_database

if [ ! -f Pfam-A.hmm ]; then
    echo -e "${YELLOW}Downloading Pfam-A.hmm.gz (~500 MB)...${NC}"
    wget -q https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
    gunzip Pfam-A.hmm.gz
    echo -e "${YELLOW}Preparing HMMER database (hmmpress)...${NC}"
    hmmpress Pfam-A.hmm
else
    echo -e "${GREEN}✓ Pfam database already prepared${NC}"
fi
cd ../../

# ---- Run HMMER domain search ----
echo -e "${GREEN}Running HMMER domain search...${NC}"
mkdir -p 05_domains/hmmer 05_domains/custom_profiles

# Example: Run hmmscan on orthogroups (adjust filenames as needed)
for ogfile in 04_orthogroups/*.fasta; do
    base=$(basename "$ogfile" .fasta)
    echo -e "${YELLOW}Analyzing ${base}...${NC}"
    hmmscan --cpu 4 --domtblout 05_domains/hmmer/${base}_domains.txt \
        05_domains/pfam_database/Pfam-A.hmm "$ogfile" > 05_domains/hmmer/${base}.log
done

# ---- Build custom HMM profiles ----
echo -e "${YELLOW}Building custom HMM profiles...${NC}"
for aln in 03_alignments/*.aln; do
    base=$(basename "$aln" .aln)
    hmmbuild 05_domains/custom_profiles/${base}.hmm "$aln" || echo -e "${RED}✗ Failed to build HMM for ${base}${NC}"
done

# ---- Run conservation analysis ----
echo -e "${YELLOW}Running domain conservation analysis...${NC}"
python3 analyze_conservation.py || echo -e "${RED}⚠ Conservation script encountered an error${NC}"

# ---- Generate summary ----
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 5 Part 1 Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "Results saved in: ${GREEN}05_domains/${NC}\n"
