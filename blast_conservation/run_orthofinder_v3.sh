#!/bin/bash

echo "========================================"
echo "Phase 2C: OrthoFinder v3.1.0 + DIAMOND"
echo "========================================"
echo ""

cd ~/PGB/MYOD1_project

# Verify tools
echo "Checking tools..."
orthofinder --version
diamond --version
echo ""

# Show input data
echo "Input data:"
for fasta in 03_orthofinder/proteomes/*.fasta; do
    if [ -s "$fasta" ]; then
        species=$(basename "$fasta" .fasta)
        seq_count=$(grep -c "^>" "$fasta")
        echo "  $species: $seq_count sequences"
    fi
done
echo ""

# Clean old results
if [ -d "03_orthofinder/results" ]; then
    echo "Removing old results..."
    rm -rf 03_orthofinder/results/
fi

echo "========================================"
echo "Running OrthoFinder"
echo "========================================"
echo ""
echo "Parameters:"
echo "  - Method: DIAMOND (ultra-fast)"
echo "  - Threads: 4"
echo "  - MSA: Yes (MAFFT)"
echo "  - Gene trees: Yes (FastTree)"
echo "  - Species tree: Yes"
echo ""
echo "Starting analysis..."
echo "Start time: $(date)"
echo ""

# Run OrthoFinder
orthofinder \
    -f 03_orthofinder/proteomes/ \
    -o 03_orthofinder/results/ \
    -t 4 \
    -a 4 \
    -S diamond \
    -M msa

# Check success
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ OrthoFinder completed successfully!"
    echo "End time: $(date)"
    echo ""
else
    echo ""
    echo "✗ OrthoFinder failed"
    exit 1
fi

# Find results directory
RESULTS_DIR=$(find 03_orthofinder/results -name "Results_*" -type d | sort | tail -n 1)

if [ -z "$RESULTS_DIR" ]; then
    echo "✗ Could not find results directory"
    exit 1
fi

echo "========================================"
echo "Analyzing Results"
echo "========================================"
echo ""
echo "Results: $RESULTS_DIR"
echo ""

# Statistics
if [ -f "$RESULTS_DIR/Comparative_Genomics_Statistics/Statistics_Overall.tsv" ]; then
    echo "=== Overall Statistics ==="
    cat "$RESULTS_DIR/Comparative_Genomics_Statistics/Statistics_Overall.tsv"
    echo ""
fi

# Orthogroups
if [ -f "$RESULTS_DIR/Orthogroups/Orthogroups.tsv" ]; then
    total=$(tail -n +2 "$RESULTS_DIR/Orthogroups/Orthogroups.tsv" | wc -l)
    echo "Total orthogroups: $total"
    echo ""
    
    # Look for MRF genes
    echo "=== Searching for MRF Family Orthogroups ==="
    grep -E "NP_002469|NP_002470|NP_005584" "$RESULTS_DIR/Orthogroups/Orthogroups.tsv" | head -n 10
    echo ""
fi

# Single-copy orthologs
if [ -f "$RESULTS_DIR/Orthogroups/Orthogroups_SingleCopyOrthologues.txt" ]; then
    single_copy=$(wc -l < "$RESULTS_DIR/Orthogroups/Orthogroups_SingleCopyOrthologues.txt")
    echo "Single-copy orthologues: $single_copy"
    echo ""
fi

# Species tree
if [ -f "$RESULTS_DIR/Species_Tree/SpeciesTree_rooted.txt" ]; then
    echo "=== Species Tree Created ==="
    cat "$RESULTS_DIR/Species_Tree/SpeciesTree_rooted.txt"
    echo ""
fi

# Gene trees
gene_trees=$(find "$RESULTS_DIR" -name "*_tree.txt" 2>/dev/null | wc -l)
echo "Gene trees: $gene_trees"
echo ""

# Copy key results
echo "Copying results to summary folder..."
mkdir -p 03_orthofinder/summary

cp "$RESULTS_DIR/Comparative_Genomics_Statistics/Statistics_Overall.tsv" 03_orthofinder/summary/ 2>/dev/null
cp "$RESULTS_DIR/Orthogroups/Orthogroups.tsv" 03_orthofinder/summary/ 2>/dev/null
cp "$RESULTS_DIR/Orthogroups/Orthogroups_SingleCopyOrthologues.txt" 03_orthofinder/summary/ 2>/dev/null
cp "$RESULTS_DIR/Species_Tree/SpeciesTree_rooted.txt" 03_orthofinder/summary/ 2>/dev/null

# Create summary
cat > 03_orthofinder/summary/orthofinder_summary.txt << EOF
OrthoFinder v3.1.0 Analysis - MYOD1 Project
============================================

Analysis completed: $(date)
Method: DIAMOND BLASTP (ultra-sensitive mode)

Species Analyzed: 11
- Mammals: Human, Mouse, Dog, Cow
- Birds: Chicken
- Fish: Zebrafish, Medaka, Fugu, Salmon
- Amphibians: Two Xenopus species

Results Location: $RESULTS_DIR

Key Findings:
-------------
Total Orthogroups: $total
Single-Copy Orthologs: $single_copy
Gene Trees Generated: $gene_trees

Key Files:
----------
- Orthogroups.tsv: Complete orthogroup assignments
- Statistics_Overall.tsv: Summary statistics
- SpeciesTree_rooted.txt: Species phylogeny
- Gene_Trees/: Individual gene family trees
- Single_Copy_Orthologue_Sequences/: Sequences for phylogeny

Analysis Details:
-----------------
1. All-vs-all sequence similarity: DIAMOND (faster than BLAST)
2. Orthogroup inference: OrthoFinder algorithm
3. Gene tree inference: FastTree
4. Species tree inference: STAG algorithm
5. Multiple sequence alignment: MAFFT

Next Steps:
-----------
1. Extract MRF orthogroups
2. Build detailed phylogenetic trees
3. Analyze domain conservation
4. Calculate selection pressure (dN/dS)
EOF

cat 03_orthofinder/summary/orthofinder_summary.txt

echo ""
echo "========================================"
echo "Phase 2C Complete!"
echo "========================================"
echo ""
echo "✓ Used DIAMOND for ultra-fast analysis"
echo "✓ Generated orthogroups and gene trees"
echo "✓ Inferred species phylogeny"
echo ""
echo "All results in: $RESULTS_DIR"
echo "Summary in: 03_orthofinder/summary/"
echo ""
echo "Ready for Phase 3: Detailed Phylogenetic Analysis"
echo ""
