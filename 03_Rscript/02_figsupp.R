library(dplyr)
library(ape)
library(ComplexHeatmap)
library(ggplot2)
library(scales)
library(patchwork)  # 
library(cowplot)
library(reshape2)

snpdist_matrix <- read.table("20251110_manuscript/Afum_LTx_variant_calling/03_Rscript/snpdist_matrix.tsv", sep="\t", header=T, row.names = 1)

snpdist_matrix[lower.tri(snpdist_matrix, diag = TRUE)] <- NA
# Melt and remove NAs
df <- na.omit(melt(snpdist_matrix))

curve_SNP <- ggplot(df, aes(value)) +
  stat_ecdf(geom = "step", pad = FALSE) +
  scale_x_continuous(labels = comma)+
  scale_y_continuous()+
  theme_bw() +
  xlab("SNP pairwise distances")+
  ylab("Empirical Cumulative Distribution Function")


##############
# distance heatmap
#pick only the necessary samples 
snpdist_matrix <- snpdist_matrix[grepl("Isolate", colnames(snpdist_matrix)),grepl("Isolate", rownames(snpdist_matrix))]
snpdist_5 <- as.matrix(snpdist_matrix)

snpdist_5[lower.tri(snpdist_5, diag = FALSE)] <- NA
snpdist_5 <- melt(snpdist_5)

heatmap_plot <- ggplot(subset(snpdist_5, !is.na(value)), aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") + # Create heatmap
  scale_fill_gradient(low = "lightyellow", high = "skyblue4") + # Set color gradient
  theme_minimal() + # Set theme
  labs(title = "SNP distances",
       fill="Number of SNPs") + # Labels
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_blank()) # Rotate x-axis labels

# Add values to the heatmap
heatmap_plot_with_values <- heatmap_plot +
  geom_text(aes(label = scales::comma(value)), color = "black", size = 2.5)


# collapse figures together for supp fig
fig_supp1 <- (curve_SNP | heatmap_plot_with_values) + 
  plot_annotation(tag_levels = 'a')+
  plot_layout(guides = 'collect',
              axes = "collect")

ggsave("fig_supp1.png", fig_supp1, width = 9, height=4.5)
ggsave("fig_supp1.svg", fig_supp1, width = 9, height=4.5)



