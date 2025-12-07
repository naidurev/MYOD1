################################################################################
# Cell State Annotation Function
# Based on module scores and marker gene expression
#
# Annotation strategy from paper:
# - Uses module scores for progenitor, proliferative, differentiated
# - Cells assigned based on highest scoring signature
# - Ground cells = low scores across all three signatures
annotate_cell_states <- function(seurat_obj, 
                                 score_threshold = 0.0,
                                 ground_threshold = -0.1) {
  # Extract scores
  prog_score <- seurat_obj$Progenitor_Score
  prolif_score <- seurat_obj$Proliferative_Score
  diff_score <- seurat_obj$Differentiated_Score
  
  # Initialize cell state vector
  cell_state <- rep("Ground", ncol(seurat_obj))
  names(cell_state) <- colnames(seurat_obj)
  
  # Create a data frame for easier manipulation
  score_df <- data.frame(
    cell = colnames(seurat_obj),
    Progenitor = prog_score,
    Proliferative = prolif_score,
    Differentiated = diff_score,
    stringsAsFactors = FALSE
  )
  
  # For each cell, assign to the state with highest score
  # But only if that score is above threshold
  for (i in 1:nrow(score_df)) {
    scores <- c(Progenitor = score_df$Progenitor[i],
                Proliferative = score_df$Proliferative[i],
                Differentiated = score_df$Differentiated[i])
    
    max_score <- max(scores)
    max_state <- names(scores)[which.max(scores)]
    
    # Assign if above threshold, otherwise remains "Ground"
    if (max_score > score_threshold) {
      cell_state[i] <- max_state
    } else if (max_score < ground_threshold) {
      # Explicitly low scores = Ground
      cell_state[i] <- "Ground"
    } else {
      # Intermediate scores where no clear winner
      # Check if two states are close
      sorted_scores <- sort(scores, decreasing = TRUE)
      if ((sorted_scores[1] - sorted_scores[2]) < 0.1) {
        # Too close to call - assign as Ground or use secondary criteria
        cell_state[i] <- "Ground"
      } else {
        cell_state[i] <- max_state
      }
    }
  }
  
  # Add to Seurat object
  seurat_obj$cell_state <- factor(cell_state, 
                                  levels = c("Progenitor", "Proliferative", 
                                             "Differentiated", "Ground"))
  return(seurat_obj)
}


################################################################################
# Alternative annotation using marker gene expression directly
################################################################################

annotate_by_markers <- function(seurat_obj) {
  
  cat("Annotating by marker gene expression...\n")
  
  # Get expression data
  expr_data <- GetAssayData(seurat_obj, slot = "data")
  
  # Define key markers for each state
  prog_markers <- c("CD44", "MEOX2", "FN1", "COL1A1")
  prolif_markers <- c("MKI67", "TOP2A", "PCNA")
  diff_markers <- c("MYOG", "TNNI1", "MYH3", "MYL4")
  
  # Filter to available genes
  prog_markers <- prog_markers[prog_markers %in% rownames(expr_data)]
  prolif_markers <- prolif_markers[prolif_markers %in% rownames(expr_data)]
  diff_markers <- diff_markers[diff_markers %in% rownames(expr_data)]
  
  # Calculate average expression for each cell
  if (length(prog_markers) > 0) {
    prog_expr <- colMeans(as.matrix(expr_data[prog_markers, , drop = FALSE]))
  } else {
    prog_expr <- rep(0, ncol(seurat_obj))
  }
  
  if (length(prolif_markers) > 0) {
    prolif_expr <- colMeans(as.matrix(expr_data[prolif_markers, , drop = FALSE]))
  } else {
    prolif_expr <- rep(0, ncol(seurat_obj))
  }
  
  if (length(diff_markers) > 0) {
    diff_expr <- colMeans(as.matrix(expr_data[diff_markers, , drop = FALSE]))
  } else {
    diff_expr <- rep(0, ncol(seurat_obj))
  }
  
  # Assign based on highest average expression
  marker_state <- rep("Ground", ncol(seurat_obj))
  
  for (i in 1:ncol(seurat_obj)) {
    expr_vec <- c(Progenitor = prog_expr[i],
                  Proliferative = prolif_expr[i],
                  Differentiated = diff_expr[i])
    
    if (max(expr_vec) > 0.5) {  # threshold
      marker_state[i] <- names(expr_vec)[which.max(expr_vec)]
    }
  }
  
  seurat_obj$cell_state_markers <- factor(marker_state,
                                          levels = c("Progenitor", "Proliferative",
                                                     "Differentiated", "Ground"))
  
  cat("\nMarker-based annotation complete.\n")
  cat("Distribution:\n")
  print(table(seurat_obj$cell_state_markers))
  
  return(seurat_obj)
}

################################################################################
# Validation function - compare module scores with marker expression
################################################################################

validate_annotations <- function(seurat_obj) {
  
  cat("\n=== Validating Annotations ===\n")
  
  # Compare score-based and marker-based annotations
  if ("cell_state_markers" %in% colnames(seurat_obj@meta.data)) {
    confusion <- table(Module_Score = seurat_obj$cell_state,
                       Marker_Based = seurat_obj$cell_state_markers)
    cat("\nConfusion Matrix (Score vs Marker-based):\n")
    print(confusion)
    
    # Calculate agreement
    agreement <- sum(diag(confusion)) / sum(confusion)
    cat("\nAgreement:", round(agreement * 100, 2), "%\n")
  }
  
  # Plot scores by assigned state
  score_by_state <- seurat_obj@meta.data %>%
    select(cell_state, Progenitor_Score, Proliferative_Score, Differentiated_Score) %>%
    tidyr::pivot_longer(cols = -cell_state, names_to = "Score_Type", values_to = "Score")
  
  p <- ggplot(score_by_state, aes(x = cell_state, y = Score, fill = Score_Type)) +
    geom_violin() +
    facet_wrap(~Score_Type) +
    theme_classic() +
    labs(title = "Module Scores by Assigned Cell State",
         x = "Cell State",
         y = "Score") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p)
  
  return(seurat_obj)
}

################################################################################
# Function to get state-specific markers
################################################################################

get_state_markers <- function(seurat_obj) {
  
  cat("\n=== Finding State-Specific Markers ===\n")
  
  Idents(seurat_obj) <- "cell_state"
  
  # Find markers for each state
  all_markers <- FindAllMarkers(seurat_obj,
                                only.pos = TRUE,
                                min.pct = 0.25,
                                logfc.threshold = 0.25,
                                verbose = FALSE)
  
  # Print top markers for each state
  for (state in unique(all_markers$cluster)) {
    cat("\nTop 10 markers for", state, ":\n")
    state_markers <- all_markers %>%
      filter(cluster == state) %>%
      arrange(desc(avg_log2FC)) %>%
      head(10)
    print(state_markers$gene)
  }
  
  return(all_markers)
}

cat("Cell state annotation functions loaded successfully!\n")
cat("\nAvailable functions:\n")
cat("  - annotate_cell_states(): Main annotation function using module scores\n")
cat("  - annotate_by_markers(): Alternative annotation using marker genes\n")
cat("  - validate_annotations(): Compare different annotation methods\n")
cat("  - get_state_markers(): Find DE genes for each cell state\n")