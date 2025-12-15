# Azole-resistant Aspergillus fumigatus in patients with cystic fibrosis and lung transplantation – prevalence and genomic profiles
Repository sharing codes used for the Scharmann et al. 2026 paper "Azole-resistant Aspergillus fumigatus in patients with cystic fibrosis and lung transplantation – prevalence and genomic profiles".

This pipeline is made in bash, and is intended to be run on a SLURM HPC. This repository is made for reproducibility of the paper's results only.

## Get started

The version of each tool ran can be found in the methods section.

The pipeline is separated into 3 main components: 
- The variant calling, from alignment to VCF files: `01_variant_calling`
- The SNP tree made using IQTree2, from the results of the variant calling section: `02_snp_tree`
- The R script to generate the figure 2 of the manuscript: `03_Rscript`