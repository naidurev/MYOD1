#!/bin/bash

echo "========================================"
echo "Phase 3: Multiple Sequence Alignment"
echo "========================================"
echo ""

cd ~/PGB/MYOD1_project

# Create directories
mkdir -p 03_alignments
mkdir -p 04_phylogeny

# Check for required tools
echo "Checking for required tools..."

if ! command -v mafft &> /dev/null; then
    echo "MAFFT not found. Installing..."
    echo "conda install -c bioconda mafft -y"
    exit 1
fi

echo "✓ MAFFT available"
echo ""

echo "========================================"
echo "Step 1: Extracting Orthogroup Sequences"
echo "========================================"
echo ""

# Parse orthogroups and extract sequences
echo "Extracting OG0000000 (MYOD1 + MYF5 group)..."

# Get accessions from OG0000000
grep "^OG0000000:" 03_orthofinder/results/Results_Nov06/Orthogroups/Orthogroups.txt | \
    sed 's/OG0000000: //' | \
    tr ' ' '\n' > 03_alignments/OG0000000_accessions.txt

OG0_COUNT=$(wc -l < 03_alignments/OG0000000_accessions.txt)
echo "  Found $OG0_COUNT sequences"

# Extract sequences for OG0000000
> 03_alignments/OG0000000_sequences.fasta

for acc in $(cat 03_alignments/OG0000000_accessions.txt); do
    # Search in all proteome files
    for fasta in 03_orthofinder/proteomes/*.fasta; do
        if grep -q "^>$acc" "$fasta"; then
            # Extract sequence
            awk -v acc="$acc" '
                BEGIN { found=0 }
                /^>/ { if ($0 ~ "^>"acc) found=1; else found=0 }
                found { print }
            ' "$fasta" >> 03_alignments/OG0000000_sequences.fasta
        fi
    done
done

SEQ0_COUNT=$(grep -c "^>" 03_alignments/OG0000000_sequences.fasta)
echo "  ✓ Extracted $SEQ0_COUNT sequences to OG0000000_sequences.fasta"
echo ""

# Extract OG0000001 (MYOG group)
echo "Extracting OG0000001 (MYOG group)..."

grep "^OG0000001:" 03_orthofinder/results/Results_Nov06/Orthogroups/Orthogroups.txt | \
    sed 's/OG0000001: //' | \
    tr ' ' '\n' > 03_alignments/OG0000001_accessions.txt

OG1_COUNT=$(wc -l < 03_alignments/OG0000001_accessions.txt)
echo "  Found $OG1_COUNT sequences"

> 03_alignments/OG0000001_sequences.fasta

for acc in $(cat 03_alignments/OG0000001_accessions.txt); do
    for fasta in 03_orthofinder/proteomes/*.fasta; do
        if grep -q "^>$acc" "$fasta"; then
            awk -v acc="$acc" '
                BEGIN { found=0 }
                /^>/ { if ($0 ~ "^>"acc) found=1; else found=0 }
                found { print }
            ' "$fasta" >> 03_alignments/OG0000001_sequences.fasta
        fi
    done
done

SEQ1_COUNT=$(grep -c "^>" 03_alignments/OG0000001_sequences.fasta)
echo "  ✓ Extracted $SEQ1_COUNT sequences to OG0000001_sequences.fasta"
echo ""

echo "========================================"
echo "Step 2: Multiple Sequence Alignment"
echo "========================================"
echo ""

# Align OG0000000
echo "Aligning OG0000000 (MYOD1/MYF5 group)..."
mafft --auto --thread 4 03_alignments/OG0000000_sequences.fasta > 03_alignments/OG0000000_aligned.fasta
echo "  ✓ Alignment complete"
echo ""

# Align OG0000001
echo "Aligning OG0000001 (MYOG group)..."
mafft --auto --thread 4 03_alignments/OG0000001_sequences.fasta > 03_alignments/OG0000001_aligned.fasta
echo "  ✓ Alignment complete"
echo ""

# Show alignment stats
echo "========================================"
echo "Alignment Statistics"
echo "========================================"
echo ""

for aln in 03_alignments/OG*_aligned.fasta; do
    og=$(basename "$aln" _aligned.fasta)
    nseq=$(grep -c "^>" "$aln")
    alen=$(grep -v "^>" "$aln" | head -n 1 | tr -d '\n' | wc -c)
    echo "$og:"
    echo "  Sequences: $nseq"
    echo "  Alignment length: $alen positions"
    echo ""
done

echo "========================================"
echo "Phase 3 Step 1-2 Complete!"
echo "========================================"
echo ""
echo "Files created:"
echo "  - 03_alignments/OG0000000_sequences.fasta"
echo "  - 03_alignments/OG0000001_sequences.fasta"
echo "  - 03_alignments/OG0000000_aligned.fasta"
echo "  - 03_alignments/OG0000001_aligned.fasta"
echo ""
echo "Next: Phylogenetic tree construction"
echo ""
