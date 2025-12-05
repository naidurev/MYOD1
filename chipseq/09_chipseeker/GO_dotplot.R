# Set CRAN mirror first
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Check if required packages are installed
if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!require("clusterProfiler", quietly = TRUE)) BiocManager::install("clusterProfiler")
if (!require("org.Mm.eg.db", quietly = TRUE)) BiocManager::install("org.Mm.eg.db")
if (!require("ggplot2", quietly = TRUE)) install.packages("ggplot2")

# Load libraries
library(clusterProfiler)
library(org.Mm.eg.db)
library(ggplot2)

# GO Enrichment Analysis
print("Running GO enrichment analysis...")
ego <- enrichGO(gene = genes,
                OrgDb = org.Mm.eg.db,
                keyType = "ENTREZID",
                ont = "BP",
                pAdjustMethod = "BH",
                pvalueCutoff = 0.05,
                qvalueCutoff = 0.05,
                readable = TRUE)

# Save GO results
write.csv(as.data.frame(ego), 
          "09_chipseeker/GO_enrichment.csv", 
          row.names=FALSE)
print("✓ GO enrichment results saved")

# Plot GO results with BETTER SPACING
pdf("09_chipseeker/GO_dotplot_wide.pdf", width=12, height=14)
dotplot(ego, showCategory=30) + 
  theme(axis.text.y = element_text(size = 9))
dev.off()
print("✓ GO dotplot (wide) saved")

# Alternative: Show only top 20 terms with more space
pdf("09_chipseeker/GO_dotplot_top20.pdf", width=12, height=10)
dotplot(ego, showCategory=20) + 
  theme(axis.text.y = element_text(size = 10))
dev.off()
print("✓ GO dotplot (top 20) saved")

pdf("09_chipseeker/GO_barplot.pdf", width=12, height=10)
barplot(ego, showCategory=20)
dev.off()
print("✓ GO barplot saved")
