library(treedataverse)
library(phangorn) #this is for midpoint

setwd("~/Documents/20240815_collab_jorge/")

#load data
annot_table <- read.csv("20251110_manuscript/Afum_LTx_variant_calling/03_Rscript/annotation_table.csv")
ploidy1 <- read.newick("20251110_manuscript/Afum_LTx_variant_calling/03_Rscript/noDP0.treefile")

#Change the names for their corresponding short ID "Isolate_[number]"
ploidy1 = rename_taxa(ploidy1, annot_table, rawID, isolateID)

#Root on the midpoint 
pl1_midpoint <- midpoint(ploidy1)
#take out 4 samples from public data TR34/L98H
pl1_reduced <- drop.tip(pl1_midpoint, c("SRR13579409", "SRR13579437", "SRR13579305", "SRR13579449"))

#plot tree with all nodes
p4 <- ggtree(pl1_midpoint)
p4 %<+% annot_table[-c(1:2)] + 
  geom_tiplab(aes(subset=!is.na(cyp51A), label=cyp51A), #print cyp51A after sample name (aligned)
              align=TRUE, offset=0.17)+
  geom_tippoint(aes(color=resistance_status), size=2.5) + #that's the tippoint colored depending on the resistance status
  geom_tiplab(aes(label=label), #only print name of the sample of the study
              data=td_filter(grepl('Isolate', label, fixed=TRUE)), 
              geom='label', fill="white", offset=0.03)+
  geom_treescale() +
  guides(color = guide_legend(title = "Azoles resistance status", #change name, size, and color of legend
                              override.aes = list(size = 5))) +
  scale_color_manual(labels = c("Resistant to ≥ 1 azole", "Susceptible"), 
                     values=c("#F25962", "#006BB6")) +
  theme(legend.text=element_text(size=12),
        legend.title=element_text(size=14))+
  ggplot2::xlim(0, 0.8)
ggsave("tree_midpoint_corrected_scaled_full_revision_noH.png", width=25, height=20, units="cm", limitsize=FALSE)


#plot tree without the 4 samples TR34/L98H
p4 <- ggtree(pl1_reduced)
p4 %<+% annot_table[-c(1:2)] + 
  geom_tiplab(aes(subset=!is.na(cyp51A), label=cyp51A), #print cyp51A after sample name (aligned)
              align=TRUE, offset=0.17)+
  geom_tippoint(aes(color=resistance_status), size=2.5) + #that's the tippoint colored depending on the resistance status
  geom_tiplab(aes(label=label), #only print name of the sample of the study
              data=td_filter(grepl('Isolate', label, fixed=TRUE)), 
              geom='label', fill="white", offset=0.03)+
  geom_treescale() +
  guides(color = guide_legend(title = "Azoles resistance status",
                              override.aes = list(size = 5))) +
  scale_color_manual(labels = c("Resistant to ≥ 1 azole", "Susceptible"), 
                     values=c("#F25962", "#006BB6")) +
  theme(legend.text=element_text(size=12),
        legend.title=element_text(size=14))+
  ggplot2::xlim(0, 0.8)
ggsave("tree_midpoint_corrected_scaled_filtered_revision_noH.png", width=25, height=20, units="cm", limitsize=FALSE)
