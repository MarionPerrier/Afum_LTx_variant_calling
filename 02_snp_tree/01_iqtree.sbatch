#!/bin/bash
#SBATCH --job-name IQTree
#SBATCH --partition=short
#SBATCH --mem=50G
#SBATCH --cpus-per-task=24
#SBATCH --ntasks=1
#SBATCH --output  out/IQTree_%a.out.%j
#SBATCH --error   out/IQTree_%a.err.%j
#SBATCH --time=03:00:00

# Load environment variables (unload all preexisting)
module purge

#-- Command section ------------------------
FOLDER=.

source ~/.bashrc
source ~/mambaforge/etc/profile.d/conda.sh

mkdir -p $FOLDER/13_snpTree

############################
##	Step1: take out sites 
## where uncalled alleles
###########################

mamba activate bcftools
bcftools view -g ^miss $FOLDER/09_SNPFilter/samples.pass.snp.vcf.gz > $FOLDER/13_snpTree/samples.noDP0.snp.vcf

############################
##	Step2: vcf2phy
## Convert a multi vcf-file into a fasta file
###########################

python3 vcf2phylip.py \
    -i $FOLDER/13_snpTree/samples.noDP0.snp.vcf \
    -f \
    --output-prefix $FOLDER/13_snpTree/samples.noDP0.snp


##########################
##	Step3: build the tree
##	with IQtree
##########################
#This needs a "pre" step where you use the fasta. Then the tool will crash by producing a .phy file that's gonna be use as input for the next step.

mamba activate iqtree

iqtree2 \
    -s $FOLDER/13_snpTree/samples.noDP0.snp.min4.fasta \
    -B 1000 \
    -m MFP+ASC+R \
	-st DNA \
    --mem 50G \
    --verbose \
    -nt AUTO

iqtree2 \
	-s $FOLDER/samples.noDP0.snp.min4.fasta.varsites.phy \
	-B 1000 \
	-m MFP+ASC+R \
	--mem 16G \
	--verbose \
	-nt AUTO
