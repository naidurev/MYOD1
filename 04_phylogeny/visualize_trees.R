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
setwd("//wsl.localhost/Ubuntu/home/naidurev/PGB/MYOD1_project/04_phylogeny")

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
