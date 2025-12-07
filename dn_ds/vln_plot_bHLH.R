library(dplyr)
library(ggplot2)

# --- Human-Chimp ---
chimp <- read.table("/home/diegovicente/Descargas/bHLH_dNdS_chimpanzee.txt",
                    header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(chimp) <- c("id", "dnds")
chimp <- chimp %>% filter(dnds > 0) %>% mutate(comparison = "Human-Chimp")

# --- Human-Mouse ---
mouse <- read.table("/home/diegovicente/Descargas/bHLH_dNdS_mouse.txt",
                    header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(mouse) <- c("id", "dnds")
mouse <- mouse %>% filter(dnds > 0) %>% mutate(comparison = "Human-Mouse")

# Combine both datasets
df_all <- bind_rows(chimp, mouse)

# Create a small data frame with the points to highlight
highlight_points <- data.frame(
  comparison = c("Human-Chimp", "Human-Mouse"),
  dnds = c(0.12690, 0.06107)
)

# Violin plot with highlighted points
ggplot(df_all, aes(x = comparison, y = dnds, fill = comparison)) +
  geom_violin(alpha = 0.7, trim = TRUE, color = NA) +
  geom_boxplot(width = 0.1, outlier.shape = NA) +
  geom_point(data = highlight_points, aes(x = comparison, y = dnds),
             color = "red", size = 3) +
  scale_y_log10() +
  scale_fill_manual(values = c("Human-Chimp" = "#F7D08A", "Human-Mouse" = "#DFF081")) +
  labs(title = "Distribution of dN/dS ratios for bHLH TFs\n(MYOD1 highlighted in red)",
       x = NULL, y = "dN/dS (log10 scale)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5))
