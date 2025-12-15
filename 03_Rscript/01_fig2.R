library(treedataverse)
library(phangorn) #this is for midpoint

#load data
annot_table <- read.csv("annotation_table.csv")
ploidy1 <- read.newick("noDP0.treefile")

#Change the names for their corresponding short ID "Sample_[number]"
ploidy1 = rename_taxa(ploidy1, annot_table, rawID, sampleID)

#Root on the midpoint 
pl1_midpoint <- midpoint(ploidy1)
#take out 4 samples from public data TR34/L98H
pl1_reduced <- drop.tip(pl1_midpoint, c("SRR13579409", "SRR13579437", "SRR13579305", "SRR13579449"))

#plot tree with all nodes
p4 <- ggtree(pl1_midpoint)
p4 %<+% annot_table[-1] + 
  geom_tiplab(aes(subset=!is.na(cyp51A), label=cyp51A), #print cyp51A after sample name (aligned)
              align=TRUE, offset=0.17)+
  geom_tippoint(aes(color=resistance_status), size=2.5) + #that's the tippoint colored depending on the resistance status
  geom_tiplab(aes(label=label), #only print name of the sample of the study
              data=td_filter(grepl('Sample', label, fixed=TRUE)), 
              geom='label', fill="white", offset=0.01)+
  geom_treescale() +
  guides(color = guide_legend(title = "Azoles resistance status", #change name, size, and color of legend
                              override.aes = list(size = 5))) +
  scale_color_manual(labels = c("Resistant to ≥ 1 azole", "Susceptible"), 
                     values=c("#F25962", "#006BB6")) +
  theme(legend.text=element_text(size=12),
        legend.title=element_text(size=14))+
  ggplot2::xlim(0, 0.8)
ggsave("tree_midpoint_corrected_scaled_full.png", width=30, height=20, units="cm", limitsize=FALSE)


#plot tree without the 4 samples TR34/L98H
p4 <- ggtree(pl1_reduced)
p4 %<+% annot_table[-1] + 
  geom_tiplab(aes(subset=!is.na(cyp51A), label=cyp51A), #print cyp51A after sample name (aligned)
              align=TRUE, offset=0.17)+
  geom_tippoint(aes(color=resistance_status), size=2.5) + #that's the tippoint colored depending on the resistance status
  geom_tiplab(aes(label=label), #only print name of the sample of the study
              data=td_filter(grepl('Sample', label, fixed=TRUE)), 
              geom='label', fill="white", offset=0.01)+
  geom_treescale() +
  guides(color = guide_legend(title = "Azoles resistance status",
                              override.aes = list(size = 5))) +
  scale_color_manual(labels = c("Resistant to ≥ 1 azole", "Susceptible"), 
                     values=c("#F25962", "#006BB6")) +
  theme(legend.text=element_text(size=12),
        legend.title=element_text(size=14))+
  ggplot2::xlim(0, 0.8)
ggsave("tree_midpoint_corrected_scaled_filtered.png", width=30, height=20, units="cm", limitsize=FALSE)
