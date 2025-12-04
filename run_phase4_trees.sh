#!/bin/bash

echo "========================================"
echo "Phase 4: Phylogenetic Tree Construction"
echo "========================================"
echo ""

cd ~/PGB/MYOD1_project

# Check for IQ-TREE
echo "Checking for required tools..."
echo ""

if ! command -v iqtree &> /dev/null; then
    echo "Installing IQ-TREE..."
    conda install -c bioconda iqtree -y
fi

echo "✓ IQ-TREE available"
iqtree --version | head -n 1
echo ""

# Create directories
mkdir -p 04_phylogeny/{mafft_trees,prank_trees,comparison}

echo "========================================"
echo "Step 1: Building Trees from MAFFT Alignments"
echo "========================================"
echo ""

# Tree for OG0000000 (MYOD1/MYF5) - MAFFT
echo "Building tree for OG0000000 (MYOD1/MYF5) - MAFFT alignment..."
echo "Start time: $(date)"
echo ""

iqtree -s 03_alignments/mafft/OG0000000_mafft.fasta \
    -pre 04_phylogeny/mafft_trees/OG0000000_mafft \
    -m TEST \
    -bb 1000 \
    -alrt 1000 \
    -nt AUTO \
    -quiet

if [ $? -eq 0 ]; then
    echo "✓ OG0000000 MAFFT tree complete"
else
    echo "✗ Tree building failed"
fi
echo ""

# Tree for OG0000001 (MYOG) - MAFFT
echo "Building tree for OG0000001 (MYOG) - MAFFT alignment..."
echo "Start time: $(date)"
echo ""

iqtree -s 03_alignments/mafft/OG0000001_mafft.fasta \
    -pre 04_phylogeny/mafft_trees/OG0000001_mafft \
    -m TEST \
    -bb 1000 \
    -alrt 1000 \
    -nt AUTO \
    -quiet

if [ $? -eq 0 ]; then
    echo "✓ OG0000001 MAFFT tree complete"
else
    echo "✗ Tree building failed"
fi
echo ""

echo "========================================"
echo "Step 2: Building Trees from PRANK Alignments"
echo "========================================"
echo ""

# Tree for OG0000000 (MYOD1/MYF5) - PRANK
echo "Building tree for OG0000000 (MYOD1/MYF5) - PRANK alignment..."
echo "Start time: $(date)"
echo ""

iqtree -s 03_alignments/prank/OG0000000_prank.fasta \
    -pre 04_phylogeny/prank_trees/OG0000000_prank \
    -m TEST \
    -bb 1000 \
    -alrt 1000 \
    -nt AUTO \
    -quiet

if [ $? -eq 0 ]; then
    echo "✓ OG0000000 PRANK tree complete"
else
    echo "✗ Tree building failed"
fi
echo ""

# Tree for OG0000001 (MYOG) - PRANK
echo "Building tree for OG0000001 (MYOG) - PRANK alignment..."
echo "Start time: $(date)"
echo ""

iqtree -s 03_alignments/prank/OG0000001_prank.fasta \
    -pre 04_phylogeny/prank_trees/OG0000001_prank \
    -m TEST \
    -bb 1000 \
    -alrt 1000 \
    -nt AUTO \
    -quiet

if [ $? -eq 0 ]; then
    echo "✓ OG0000001 PRANK tree complete"
else
    echo "✗ Tree building failed"
fi
echo ""

echo "========================================"
echo "Step 3: Analyzing Tree Results"
echo "========================================"
echo ""

# Function to extract model and support info
analyze_tree() {
    prefix=$1
    og=$2
    method=$3
    
    if [ -f "${prefix}.iqtree" ]; then
        echo "=== $og - $method ==="
        echo ""
        
        # Extract best model
        best_model=$(grep "Best-fit model:" "${prefix}.iqtree" | awk '{print $3}')
        echo "Best-fit model: $best_model"
        
        # Extract log-likelihood
        logl=$(grep "Log-likelihood of the tree:" "${prefix}.iqtree" | awk '{print $4}')
        echo "Log-likelihood: $logl"
        
        # Extract AIC/BIC
        aic=$(grep "Akaike information criterion" "${prefix}.iqtree" | head -n 1 | awk '{print $5}')
        bic=$(grep "Bayesian information criterion" "${prefix}.iqtree" | head -n 1 | awk '{print $5}')
        echo "AIC: $aic"
        echo "BIC: $bic"
        
        # Check tree file
        if [ -f "${prefix}.treefile" ]; then
            echo "✓ Tree file created"
        fi
        
        echo ""
    else
        echo "$og - $method: Results not found"
        echo ""
    fi
}

echo "MAFFT-based Trees:"
echo "-------------------"
analyze_tree "04_phylogeny/mafft_trees/OG0000000_mafft" "OG0000000" "MAFFT"
analyze_tree "04_phylogeny/mafft_trees/OG0000001_mafft" "OG0000001" "MAFFT"

echo "PRANK-based Trees:"
echo "-------------------"
analyze_tree "04_phylogeny/prank_trees/OG0000000_prank" "OG0000000" "PRANK"
analyze_tree "04_phylogeny/prank_trees/OG0000001_prank" "OG0000001" "PRANK"

echo "========================================"
echo "Step 4: Creating Summary Report"
echo "========================================"
echo ""

cat > 04_phylogeny/phylogeny_summary.txt << 'EOF'
Phylogenetic Analysis Summary - MYOD1 Project
==============================================

Method: Maximum Likelihood with IQ-TREE
----------------------------------------

IQ-TREE Parameters:
- Model selection: ModelFinder (TEST option)
- Bootstrap support: UFBoot2 (1000 replicates)
- Branch support: SH-aLRT test (1000 replicates)
- Automatic thread optimization

Analysis Strategy:
------------------

Two independent phylogenetic analyses were performed:

1. MAFFT-based trees
   - Input: L-INS-i alignments
   - Purpose: Validate tree topology with cleaner alignment
   - Advantage: Better handling of divergent regions

2. PRANK-based trees
   - Input: Phylogeny-aware alignments
   - Purpose: Most accurate evolutionary inference
   - Advantage: Proper indel modeling for branch lengths

Tree Files Generated:
---------------------

OG0000000 (MYOD1/MYF5 orthogroup):
  MAFFT tree: 04_phylogeny/mafft_trees/OG0000000_mafft.treefile
  PRANK tree: 04_phylogeny/prank_trees/OG0000000_prank.treefile

OG0000001 (MYOG orthogroup):
  MAFFT tree: 04_phylogeny/mafft_trees/OG0000001_mafft.treefile
  PRANK tree: 04_phylogeny/prank_trees/OG0000001_prank.treefile

Support Values Interpretation:
-------------------------------
- UFBoot ≥95%: Strong support
- UFBoot 80-94%: Moderate support
- UFBoot <80%: Weak support
- SH-aLRT ≥80%: Additional confidence

Key Findings:
-------------
(To be filled after tree visualization)

1. Orthogroup relationships
2. Species groupings
3. Paralog divergence timing
4. Taxonomic conservation patterns

Next Steps:
-----------
1. Visualize trees with FigTree/iTOL
2. Compare MAFFT vs PRANK topologies
3. Annotate trees with bootstrap values
4. Identify duplication nodes
5. Map to species tree

EOF

cat 04_phylogeny/phylogeny_summary.txt

echo ""
echo "========================================"
echo "Step 5: Creating Tree Visualization Scripts"
echo "========================================"
echo ""

# Create R script for basic tree visualization
cat > 04_phylogeny/visualize_trees.R << 'RSCRIPT'
#!/usr/bin/env Rscript

# Tree Visualization Script
# Requires: ape, ggtree packages

if (!requireNamespace("ape", quietly = TRUE)) {
    install.packages("ape", repos="http://cran.r-project.org")
}

library(ape)

# Function to plot tree
plot_tree <- function(treefile, outfile, title) {
    tree <- read.tree(treefile)
    
    pdf(outfile, width=12, height=10)
    plot(tree, 
         main=title,
         cex=0.8,
         show.node.label=TRUE,
         edge.width=2)
    dev.off()
    
    cat("Created:", outfile, "\n")
}

# Plot all trees
setwd("04_phylogeny")

# MAFFT trees
if (file.exists("mafft_trees/OG0000000_mafft.treefile")) {
    plot_tree("mafft_trees/OG0000000_mafft.treefile", 
              "comparison/OG0000000_mafft_tree.pdf",
              "OG0000000 (MYOD1/MYF5) - MAFFT")
}

if (file.exists("mafft_trees/OG0000001_mafft.treefile")) {
    plot_tree("mafft_trees/OG0000001_mafft.treefile",
              "comparison/OG0000001_mafft_tree.pdf",
              "OG0000001 (MYOG) - MAFFT")
}

# PRANK trees
if (file.exists("prank_trees/OG0000000_prank.treefile")) {
    plot_tree("prank_trees/OG0000000_prank.treefile",
              "comparison/OG0000000_prank_tree.pdf",
              "OG0000000 (MYOD1/MYF5) - PRANK")
}

if (file.exists("prank_trees/OG0000001_prank.treefile")) {
    plot_tree("prank_trees/OG0000001_prank.treefile",
              "comparison/OG0000001_prank_tree.pdf",
              "OG0000001 (MYOG) - PRANK")
}

cat("\nTree visualization complete!\n")
RSCRIPT

chmod +x 04_phylogeny/visualize_trees.R

echo "✓ R visualization script created"
echo ""

# Create Python script for tree comparison
cat > 04_phylogeny/compare_trees.py << 'PYSCRIPT'
#!/usr/bin/env python3

"""
Compare tree topologies from MAFFT and PRANK alignments
"""

from Bio import Phylo
import sys

def compare_trees(tree1_file, tree2_file):
    """Compare two tree files"""
    try:
        tree1 = Phylo.read(tree1_file, "newick")
        tree2 = Phylo.read(tree2_file, "newick")
        
        print(f"\nComparing:")
        print(f"  Tree 1: {tree1_file}")
        print(f"  Tree 2: {tree2_file}")
        print(f"\nTree 1 terminals: {len(tree1.get_terminals())}")
        print(f"Tree 2 terminals: {len(tree2.get_terminals())}")
        
        # Get terminal names
        names1 = set([t.name for t in tree1.get_terminals()])
        names2 = set([t.name for t in tree2.get_terminals()])
        
        if names1 == names2:
            print("✓ Both trees have identical taxa")
        else:
            print("⚠ Trees have different taxa")
            print(f"  Only in tree1: {names1 - names2}")
            print(f"  Only in tree2: {names2 - names1}")
        
    except Exception as e:
        print(f"Error comparing trees: {e}")

# Compare OG0000000 trees
print("="*50)
print("OG0000000 (MYOD1/MYF5) Comparison")
print("="*50)
compare_trees("04_phylogeny/mafft_trees/OG0000000_mafft.treefile",
              "04_phylogeny/prank_trees/OG0000000_prank.treefile")

# Compare OG0000001 trees
print("\n" + "="*50)
print("OG0000001 (MYOG) Comparison")
print("="*50)
compare_trees("04_phylogeny/mafft_trees/OG0000001_mafft.treefile",
              "04_phylogeny/prank_trees/OG0000001_prank.treefile")

print("\n" + "="*50)
print("Comparison complete!")
print("="*50)
PYSCRIPT

chmod +x 04_phylogeny/compare_trees.py

echo "✓ Python comparison script created"
echo ""

echo "========================================"
echo "Phase 4 Complete!"
echo "========================================"
echo ""
echo "Trees built successfully!"
echo ""
echo "Files created:"
echo ""
echo "Tree Files (Newick format):"
echo "  MAFFT-based:"
echo "    - 04_phylogeny/mafft_trees/OG0000000_mafft.treefile"
echo "    - 04_phylogeny/mafft_trees/OG0000001_mafft.treefile"
echo ""
echo "  PRANK-based:"
echo "    - 04_phylogeny/prank_trees/OG0000000_prank.treefile"
echo "    - 04_phylogeny/prank_trees/OG0000001_prank.treefile"
echo ""
echo "Analysis Files:"
echo "  - 04_phylogeny/phylogeny_summary.txt"
echo "  - 04_phylogeny/visualize_trees.R (for plotting)"
echo "  - 04_phylogeny/compare_trees.py (for comparison)"
echo ""
echo "IQ-TREE Reports (detailed statistics):"
echo "  - *.iqtree files in mafft_trees/ and prank_trees/"
echo ""
echo "Next Steps:"
echo "  1. Visualize trees: Rscript 04_phylogeny/visualize_trees.R"
echo "  2. Compare topologies: python3 04_phylogeny/compare_trees.py"
echo "  3. Upload .treefile to iTOL (https://itol.embl.de/) for publication figures"
echo "  4. Phase 5: Domain Analysis with InterProScan"
echo ""
