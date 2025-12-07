################################################################################
# MYOD1 Mutation Analysis in Rhabdomyosarcoma
# Comparing MSK74711 (MYOD1^L122R) vs Mast111 (WT FN-RMS)
################################################################################

# Load required libraries
library(Seurat)
library(dplyr)
library(ggplot2)
library(patchwork)
library(RColorBrewer)
library(viridis)
library(gridExtra)

# SWD
setwd("/home/tanase/Documents/master/Term1/PGB/The_bHLH_project/thanos_pgb")
rm(list = ls())
# Reproducibility
set.seed(42)


################################################################################
# 1 - LOAD DATA
################################################################################
# These should be the raw/processed data from GEO: GSE195709
mutant_old <- readRDS("GSM5848693_20191031_MSK74711_seurat-object.rds")
mutant <- UpdateSeuratObject(mutant_old)
rm(mutant_old)  # Free memory

wt_old <- readRDS("GSM5848682_20190624_seurat-object_MAST111.rds")
wt <- UpdateSeuratObject(wt_old)
rm(wt_old)  # Free memory

# Get raw counts
mutant_raw_counts <- GetAssayData(mutant, layer = "counts")
wt_raw_counts <- GetAssayData(wt, layer = "counts")

# Get metadata (QC info included)
mutant_metadata <- mutant@meta.data[,1:7]
wt_metadata <- wt@meta.data[,1:10]

# Create new objects with ONLY raw counts
mutant_fresh <- CreateSeuratObject(
  counts = mutant_raw_counts,
  project = "MSK74711",
  min.cells = 0,  # Don't filter - already QC'd
  min.features = 0  # Don't filter - already QC'd
)

wt_fresh <- CreateSeuratObject(
  counts = wt_raw_counts,
  project = "Mast111",
  min.cells = 0,
  min.features = 0
)

# Add back important metadata
mutant_fresh <- AddMetaData(mutant_fresh, metadata = mutant_metadata)
wt_fresh <- AddMetaData(wt_fresh, metadata = wt_metadata)

# Add sample identity to metadata
mutant_fresh$sample <- "MYOD1_mutant"
mutant_fresh$condition <- "MYOD1_L122R"
wt_fresh$sample <- "WT_FN-RMS"
wt_fresh$condition <- "Wild_Type"

# Save the fresh Seurat objects
saveRDS(mutant_fresh, file = "mutant_processed.rds")
saveRDS(wt_fresh, file = "wt_processed.rds")


aa <- VlnPlot(mutant_fresh, 
        features = c("nFeature_RNA", "nCount_RNA", "percent.mito"), 
        ncol = 3, 
        pt.size = 0.1)


################################################################################
# 2 - STANDARD PREPROCESSING
################################################################################
# Create output directory
dir.create("results", showWarnings = FALSE)

# Function to preprocess individual samples
preprocess_sample <- function(seurat_obj, sample_name) {

  # Normalize (log-normalization with scale factor 1e6)
  seurat_obj <- NormalizeData(seurat_obj, 
                              normalization.method = "LogNormalize",
                              scale.factor = 1e6)

  # Find variable features (2000)
  seurat_obj <- FindVariableFeatures(seurat_obj, 
                                     selection.method = "vst",
                                     nfeatures = 2000)
  # Scale data
  seurat_obj <- ScaleData(seurat_obj)
  
  # PCA
  seurat_obj <- RunPCA(seurat_obj, 
                       features = VariableFeatures(object = seurat_obj))
  
  return(seurat_obj)
}


# Process sample/s
mutant_fresh <- preprocess_sample(mutant_fresh, "MYOD1_mutant")
#wt_fresh <- preprocess_sample(wt_fresh, "WT_FN-RMS")


################################################################################
# 3 - Plot highly variable features
################################################################################
## MYOD1_mutant
top10 <- head(VariableFeatures(mutant_fresh), 10)
# Create base plot
plot1 <- VariableFeaturePlot(mutant_fresh) +
  theme_classic(base_size = 10) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 10),
    axis.title = element_text(face = "bold"),
    legend.position = "none"
  ) +
  labs(
    title = "A. Highly Variable Features - MYOD1 Mutant",
    x = "Average Expression",
    y = "Standardized Variance"
  )

# Add labeled points with better styling
plot2 <- LabelPoints(
  plot = plot1, 
  points = top10, 
  repel = TRUE,
  max.overlaps = Inf,
  size = 2,
  fontface = "bold",
  box.padding = 0.5,
  point.padding = 0.3
)

# Save single clean plot
ggsave(
  "results/hvf_top10_MYOD1_mutant.png", 
  plot = plot2, 
  width = 4, 
  height = 4, 
  dpi = 300,
  bg = "white"
)


## WT_FN-RMS
top10 <- head(VariableFeatures(wt_fresh), 10)
# Create base plot
plot3 <- VariableFeaturePlot(wt_fresh) +
  theme_classic(base_size = 10) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 10),
    axis.title = element_text(face = "bold"),
    legend.position = "none"
  ) +
  labs(
    title = "A. Highly Variable Features - WT_FN-RMS",
    x = "Average Expression",
    y = "Standardized Variance"
  )

# Add labeled points with better styling
plot4 <- LabelPoints(
  plot = plot3, 
  points = top10, 
  repel = TRUE,
  max.overlaps = Inf,
  size = 2,
  fontface = "bold",
  box.padding = 0.5,
  point.padding = 0.3
)

# Save single clean plot
ggsave(
  "results/hvf_top10_WT_FN-RMS.png", 
  plot = plot4, 
  width = 4, 
  height = 4, 
  dpi = 300,
  bg = "white"
)

################################################################################
## 4 - Elbow plots to determine dimensionality
################################################################################
p_elbow_mutant <- ElbowPlot(mutant_fresh, ndims = 50) + ggtitle("B. Elbow plot - MYOD1 Mutant")
#p_elbow_wt <- ElbowPlot(wt_fresh, ndims = 50) + ggtitle("WT FN-RMS")
png("results/phase1_initial_exploration/elbow_both.png", width = 4000, height = 1500, res = 300)
#print(p_elbow_mutant + p_elbow_wt)
dev.off()

# Define number of PCs
n_dims <- 30


## Combine plots for mutant side by side (Plot highly variable features / Elbow plots)
library(patchwork)
combined_plot <- plot2 + p_elbow_mutant

# Save as SVG
ggsave("variable_features_and_elbow.png", 
       combined_plot, 
       width = 12, 
       height = 5)


# Display
print(combined_plot)

# Percentage of variance explained by each PC
pct <- mutant_fresh[["pca"]]@stdev / sum(mutant_fresh[["pca"]]@stdev) * 100

# Cumulative variance for first 30 PCs
cumulative_pct_30 <- sum(pct[1:30])
cat(sprintf("First 30 PCs explain %.2f%% of variance\n", cumulative_pct_30))




################################################################################
# 3 - LOAD CELL STATE GENE SIGNATURES
################################################################################
# Extract gene lists (remove NA values)

signatures_df <- read.csv("gene_signatures.csv", header = T, fill = T, na.strings = c("","NA"), stringsAsFactors = FALSE)

progenitor_genes <- signatures_df$progenitor[!is.na(signatures_df$progenitor)]
proliferative_genes <- signatures_df$proliferative[!is.na(signatures_df$proliferative)]
differentiated_genes <- signatures_df$differentiated[!is.na(signatures_df$differentiated)]


################################################################################
# 4 - ANNOTATE CELLS WITH MODULE SCORES
################################################################################
# Function to add module scores
add_cell_state_scores <- function(seurat_obj) {
  # Add module scores for each cell state
  # Following paper's method: AddModuleScore with n=100 control genes
  
  seurat_obj <- AddModuleScore(
    object = seurat_obj,
    features = list(progenitor_genes),
    name = "Progenitor_Score",
    ctrl = 100
  )
  
  seurat_obj <- AddModuleScore(
    object = seurat_obj,
    features = list(proliferative_genes),
    name = "Proliferative_Score",
    ctrl = 100
  )
  
  seurat_obj <- AddModuleScore(
    object = seurat_obj,
    features = list(differentiated_genes),
    name = "Differentiated_Score",
    ctrl = 100
  )
  
  # Rename columns (AddModuleScore adds "1" suffix)
  colnames(seurat_obj@meta.data)[colnames(seurat_obj@meta.data) == "Progenitor_Score1"] <- "Progenitor_Score"
  colnames(seurat_obj@meta.data)[colnames(seurat_obj@meta.data) == "Proliferative_Score1"] <- "Proliferative_Score"
  colnames(seurat_obj@meta.data)[colnames(seurat_obj@meta.data) == "Differentiated_Score1"] <- "Differentiated_Score"
  
  # Calculate muscle lineage score (Differentiated - Progenitor)
  seurat_obj$Muscle_Lineage_Score <- seurat_obj$Differentiated_Score - seurat_obj$Progenitor_Score
  
  return(seurat_obj)
}

mutant_fresh <- add_cell_state_scores(mutant_fresh)
#wt_fresh <- add_cell_state_scores(wt_fresh)

################################################################################
# 6 - CELL STATE ANNOTATION (Rule-based)
################################################################################
# Source annotation function
source("cell_state_annotation.R")

# Annotate cells
mutant_fresh <- annotate_cell_states(mutant_fresh)
wt_fresh <- annotate_cell_states(wt_fresh)

# Summary of cell states
cat("\nMutant cell state distribution:\n")
print(table(mutant_fresh$cell_state))

cat("\nWT cell state distribution:\n")
print(table(wt_fresh$cell_state))




################################################################################
# 7 - CLUSTERING AND UMAP FOR INDIVIDUAL SAMPLES
################################################################################
# Function for clustering and UMAP
cluster_and_umap <- function(seurat_obj, dims = 15, resolution = 0.3) {
  # Find neighbors
  seurat_obj <- FindNeighbors(seurat_obj, dims = 1:dims)
  
  # Clustering (resolution 0.3 as per paper for individual samples)
  seurat_obj <- FindClusters(seurat_obj, resolution = resolution)
  
  # Run UMAP
  seurat_obj <- RunUMAP(seurat_obj, dims = 1:dims)
  
  return(seurat_obj)
}

mutant_fresh <- cluster_and_umap(mutant_fresh, dims = n_dims, resolution = 0.5)
#wt_fresh <- cluster_and_umap(wt_fresh, dims = n_dims, resolution = 0.5)




################################################################################
# 8 - INITIAL EXPLORATION
################################################################################

## 8.1: UMAP by clusters
p1 <- DimPlot(mutant_fresh, reduction = "umap", label = TRUE) + 
  ggtitle("A. MYOD1 Mutant - Clusters") +
  theme(legend.position = "right")

p2 <- DimPlot(wt_fresh, reduction = "umap", label = TRUE) + 
  ggtitle("WT FN-RMS - Clusters") +
  theme(legend.position = "right")

pdf("results/01_UMAPs_by_cluster.pdf", width = 14, height = 6)
print(p1 + p2)
dev.off()

## 8.2: UMAP by cell state
p3 <- DimPlot(mutant_fresh, reduction = "umap", group.by = "cell_state", label = FALSE) + 
  ggtitle("B. MYOD1 Mutant - Cell States") +
  scale_color_manual(values = c("Progenitor" = "#E41A1C",
                                "Proliferative" = "#377EB8", 
                                "Differentiated" = "#4DAF4A",
                                "Ground" = "#999999"))

p4 <- DimPlot(wt_fresh, reduction = "umap", group.by = "cell_state", label = FALSE) + 
  ggtitle("WT FN-RMS - Cell States") +
  scale_color_manual(values = c("Progenitor" = "#E41A1C",
                                "Proliferative" = "#377EB8",
                                "Differentiated" = "#4DAF4A",
                                "Ground" = "#999999"))
ggsave("UMAPs.png", 
       p1+p3, 
       width = 12, 
       height = 5, 
       dpi = 300)


pdf("results/02_UMAPs_by_cell_state.pdf", width = 14, height = 6)
print(p3 + p4)
dev.off()

# ## 8.3: MYOD1 expression overlay
# p5 <- FeaturePlot(mutant_fresh, features = "MYOD1", reduction = "umap") + 
#   ggtitle("MYOD1 Expression - Mutant")
# 
# p6 <- FeaturePlot(wt_fresh, features = "MYOD1", reduction = "umap") + 
#   ggtitle("MYOD1 Expression - WT") +
#   scale_color_viridis(option = "plasma")
# 
# pdf("results/phase1_initial_exploration/03_MYOD1_expression_UMAPs.pdf", width = 14, height = 6)
# print(p5 + p6)
# dev.off()
# 
# ## 8.4: Cell state scores overlay
# feature_list <- c("Progenitor_Score", "Proliferative_Score", 
#                   "Differentiated_Score", "Muscle_Lineage_Score")
# 
# for (feat in feature_list) {
#   p_mut <- FeaturePlot(mutant_fresh, features = feat, reduction = "umap") + 
#     ggtitle(paste0(feat, " - Mutant"))
#   p_wt <- FeaturePlot(wt_fresh, features = feat, reduction = "umap") + 
#     ggtitle(paste0(feat, " - WT"))
#   
#   pdf(paste0("results/phase1_initial_exploration/04_", feat, "_UMAPs.pdf"), 
#       width = 14, height = 6)
#   print(p_mut + p_wt)
#   dev.off()
# }


################################################################################
# Find marker genes for MyoD1-expressing cells in the samples
################################################################################

# Function to identify MyoD1+ cells and find markers
find_myod1_markers <- function(seurat_obj, sample_name) {
  
  # Get MyoD1 expression data
  myod1_expression <- GetAssayData(seurat_obj, slot = "data")["MYOD1", ]
  
  # Define MyoD1+ cells (expression > 0)
  # Adjust threshold if needed (e.g., > 0.5 for more stringent)
  myod1_positive <- names(myod1_expression[myod1_expression > 0])
  myod1_negative <- names(myod1_expression[myod1_expression == 0])
  
  cat(sprintf("\n%s: %d MyoD1+ cells, %d MyoD1- cells\n", 
              sample_name, length(myod1_positive), length(myod1_negative)))
  
  # Add identity to metadata
  seurat_obj$myod1_status <- ifelse(colnames(seurat_obj) %in% myod1_positive, 
                                    "MyoD1_pos", "MyoD1_neg")
  
  # Set identity for differential expression
  Idents(seurat_obj) <- "myod1_status"
  
  # Find markers: MyoD1+ vs all other cells
  markers <- FindMarkers(
    seurat_obj,
    only.pos = F,
    ident.1 = "MyoD1_pos",
    ident.2 = "MyoD1_neg",
    min.pct = 0.25,           # Expressed in at least 25% of cells
    logfc.threshold = 0.5,   # Minimum log2 fold change,
    test.use = "wilcox"       # Wilcoxon rank sum test (default)
  )
  
  # Add gene names as column
  markers$gene <- rownames(markers)
  
  # Sort by avg_log2FC
  markers <- markers[order(-markers$avg_log2FC), ]
  
  return(list(seurat_obj = seurat_obj, markers = markers))
}


##############################
##############################
mutant_results <- find_myod1_markers(mutant_fresh, "Mutant")
mutant_markers <- mutant_results$markers

wt_results <- find_myod1_markers(wt_fresh, "WT")
wt_markers <- wt_results$markers

write.csv(wt_markers, "results/myod1_markers_wt.csv", row.names = FALSE)
write.csv(mutant_markers, "results/myod1_markers_mut.csv", row.names = FALSE)

################################################################################
#Correlation analysis of MyoD1 marker genes between mutant and WT samples
################################################################################
# Prepare data for correlation analysis
# Get union of all genes from both datasets
all_genes <- union(mutant_markers$gene, wt_markers$gene)

# Create complete dataframes with all genes
# Genes not present in a sample get avg_log2FC = 0
# Mutant data
mutant_complete <- data.frame(
  gene = all_genes,
  stringsAsFactors = FALSE
)
mutant_complete <- merge(mutant_complete, 
                         mutant_markers[, c("gene", "avg_log2FC", "p_val_adj")],
                         by = "gene", 
                         all.x = TRUE)
mutant_complete$avg_log2FC[is.na(mutant_complete$avg_log2FC)] <- 0
mutant_complete$p_val_adj[is.na(mutant_complete$p_val_adj)] <- 1
colnames(mutant_complete) <- c("gene", "mutant_log2FC", "mutant_padj")

# WT data
wt_complete <- data.frame(
  gene = all_genes,
  stringsAsFactors = FALSE
)
wt_complete <- merge(wt_complete, 
                     wt_markers[, c("gene", "avg_log2FC", "p_val_adj")],
                     by = "gene", 
                     all.x = TRUE)
wt_complete$avg_log2FC[is.na(wt_complete$avg_log2FC)] <- 0
wt_complete$p_val_adj[is.na(wt_complete$p_val_adj)] <- 1
colnames(wt_complete) <- c("gene", "wt_log2FC", "wt_padj")

# Merge into single dataframe
correlation_data <- merge(mutant_complete, wt_complete, by = "gene")
# Save correlation data
write.csv(correlation_data, "results/myod1_marker_correlation.csv", row.names = FALSE)

# Capture MYOD1 logFC values
myod1_logFC <- correlation_data[correlation_data$gene == "MYOD1", ]

# Exclude MYOD1 from correlation analysis
correlation_data <- correlation_data[correlation_data$gene != "MYOD1", ]

# ---------------------------------------------------------
# Focus on genes with |log2FC| > 0.5 in at least one sample
# correlation_data <- correlation_data %>%
#   filter(abs(mutant_log2FC) > 0.5 | abs(wt_log2FC) > 0.5)
# ---------------------------------------------------------

#Calculate correlation
correlation <- cor(correlation_data$mutant_log2FC, 
                   correlation_data$wt_log2FC, 
                   method = "pearson")

# Identify MyoD1 for highlighting
#correlation_data$is_myod1 <- grepl("MYOD1", correlation_data$gene, ignore.case = TRUE)

common_genes <- intersect(mutant_markers$gene, wt_markers$gene)
common_genes <- setdiff(common_genes, "MYOD1")

# Filter data: exclude genes with 0 in both samples and MyoD1
plot_data <- correlation_data[correlation_data$gene %in% common_genes,]

# ===== FIND TOP DISCORDANT GENES (ALL GENES) =====
plot_data$abs_diff <- abs(plot_data$mutant_log2FC - plot_data$wt_log2FC)

plot_data <- plot_data[plot_data$wt_padj != 1, ]
plot_data <- plot_data[plot_data$mutant_padj != 1, ]


top_discordant_all <- plot_data %>%
  arrange(desc(abs_diff)) %>%
  select(gene, mutant_log2FC, wt_log2FC, abs_diff) %>%
  head(30)

# Save for cross-check with ChIP-seq enrichment analysis
write.csv(top_discordant_all, "results/top_discordant_genes.csv", row.names = FALSE)

correlation1 <- cor(plot_data$mutant_log2FC, 
                    plot_data$wt_log2FC, 
                    method = "pearson")

# Create scatter plot
# Calculate symmetrical axis limits
max_abs <- max(abs(c(plot_data$wt_log2FC, plot_data$mutant_log2FC)))
axis_limits <- c(-max_abs, max_abs)

# Create scatter plot with equal axes
p <- ggplot(plot_data, aes(x = wt_log2FC, y = mutant_log2FC)) +
  geom_point(data = plot_data[!plot_data$gene %in% top_discordant_all$gene, ],
             alpha = 0.6, size = 2.5, color = "steelblue") +
  geom_point(data = plot_data[plot_data$gene %in% top_discordant_all$gene, ],
             alpha = 0.6, size = 2.5, color = "red") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50", alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dotted", color = "gray50", alpha = 0.5) +
  coord_fixed(ratio = 1, xlim = axis_limits, ylim = axis_limits) +  # This ensures equal scaling
  labs(
    title = "MyoD1+ Marker Genes: Mutant vs WT",
    subtitle = sprintf("Pearson r = %.3f (n=%d genes, top 30 discordant in red)", 
                       correlation1, nrow(plot_data)),
    x = "WT avg_log2FC",
    y = "Mutant avg_log2FC"
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    aspect.ratio = 1  # Ensures square plot
  )

ggsave("results/myod1_correlation_final.pdf", p, width = 8, height = 8)
ggsave("results/myod1_correlation_final.png", p, width = 8, height = 8, dpi = 300)
print(p)
################################################################################
################################################################################

