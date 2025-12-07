library(dplyr)
library(ggplot2)

# --- Full-genome datasets ---
chimp <- read.table("/home/diegovicente/Descargas/full_genome_dNdS_chimpanzee.txt",
                    header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(chimp) <- c("id", "dnds")
chimp <- chimp %>% filter(dnds > 0) %>% mutate(comparison = "Human-Chimp")

mouse <- read.table("/home/diegovicente/Descargas/full_genome_dNdS_mouse.txt",
                    header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(mouse) <- c("id", "dnds")
mouse <- mouse %>% filter(dnds > 0) %>% mutate(comparison = "Human-Mouse")

# Combine full-genome datasets
df_all <- bind_rows(chimp, mouse)

# --- bHLH transcription factors ---
bhlh_chimp <- read.table("/home/diegovicente/Descargas/bHLH_dNdS_chimpanzee.txt",
                         header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(bhlh_chimp) <- c("id", "dnds")
bhlh_chimp <- bhlh_chimp %>% filter(dnds > 0) %>% mutate(comparison = "Human-Chimp")

bhlh_mouse <- read.table("/home/diegovicente/Descargas/bHLH_dNdS_mouse.txt",
                         header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(bhlh_mouse) <- c("id", "dnds")
bhlh_mouse <- bhlh_mouse %>% filter(dnds > 0) %>% mutate(comparison = "Human-Mouse")

# Combine bHLH datasets
bhlh_all <- bind_rows(bhlh_chimp, bhlh_mouse)

# --- Plot ---
ggplot(df_all, aes(x = comparison, y = dnds, fill = comparison)) +
  geom_violin(alpha = 0.7, trim = TRUE, color = NA) +
  geom_boxplot(width = 0.1, outlier.shape = NA) +
  geom_jitter(data = bhlh_all, aes(x = comparison, y = dnds),
              color = "red", size = 2, width = 0.15) +  # highlight bHLH TFs
  scale_y_log10() +
  scale_fill_manual(values = c("Human-Chimp" = "#F7D08A", "Human-Mouse" = "#DFF081")) +
  labs(title = "Distribution of dN/dS ratios genome-wide\n(bHLH TFs highlighted in red)",
       x = NULL, y = "dN/dS (log10 scale)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5))
