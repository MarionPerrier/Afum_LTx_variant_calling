#!/bin/bash
#SBATCH --job-name dbVariant
#SBATCH --partition=short
#SBATCH --array=1-9
#SBATCH --mem=48G
#SBATCH --cpus-per-task=24
#SBATCH --ntasks=1
#SBATCH --output  out/dbVariant_%a.out.%j
#SBATCH --error   out/dbVariant_%a.err.%j
#SBATCH --time=03:00:00

#this has to be run separately because we are not
#doing a sarray on the samples but on the chromosomes. 

# Load environment variables (unload all preexisting)
module purge

#-- Command section ------------------------

FOLDER=.
REF=~/references/gatk4/Af293_FungiDB_v68/FungiDB-68_AfumigatusAf293_Genome.fasta
IMG=docker://broadinstitute/gatk:4.6.0.0

source ~/.bashrc
source ~/mambaforge/etc/profile.d/conda.sh

mkdir -p $FOLDER/07_GenomicsDBImport $FOLDER/08_genotypeVCF

######################
##	Step8: GenomicsDBImport
## This step consolidates the contents of GVCF files accross samples (see gatk manual)
## This step is ran separately, as it needs to be ran once per chromosome with all the samples.
######################
mkdir -p $FOLDER/07_GenomicsDBImport/tmp 
{
if [ $SLURM_ARRAY_TASK_ID -eq 9 ]; then
singularity run $IMG \
gatk --java-options "-Xmx4g -Xms4g" GenomicsDBImport \
	--genomicsdb-workspace-path $FOLDER/07_GenomicsDBImport/mito \
	--sample-name-map $FOLDER/cohort.p1.sample_map \
	--tmp-dir $FOLDER/07_GenomicsDBImport/tmp \
	--genomicsdb-shared-posixfs-optimizations \
	--reader-threads 2 \
	-L mito_A_fumigatus_Af293

else 

singularity run $IMG \
gatk --java-options "-Xmx4g -Xms4g" GenomicsDBImport \
	--genomicsdb-workspace-path $FOLDER/07_GenomicsDBImport/Chr${SLURM_ARRAY_TASK_ID} \
	--sample-name-map $FOLDER/cohort.p1.sample_map \
	--tmp-dir $FOLDER/07_GenomicsDBImport/tmp \
	--genomicsdb-shared-posixfs-optimizations \
	--reader-threads 2 \
	-L Chr${SLURM_ARRAY_TASK_ID}_A_fumigatus_Af293
fi
}

#####################
##	Step9: GenotypeGVCFs
##	Gather all gVCF together before filtering
#####################
mkdir -p $FOLDER/08_genotypeVCF/tmp
{
if [ $SLURM_ARRAY_TASK_ID -eq 9 ]; then
singularity run $IMG \
gatk --java-options "-Xmx4g" GenotypeGVCFs \
	-R $REF \
	-V gendb://$FOLDER/07_GenomicsDBImport/mito \
	-O $FOLDER/08_genotypeVCF/mito.vcf.gz \
	--tmp-dir $FOLDER/08_genotypeVCF/tmp
else
singularity run $IMG \
gatk --java-options "-Xmx4g" GenotypeGVCFs \
	-R $REF \
	-V gendb://$FOLDER/07_GenomicsDBImport/Chr${SLURM_ARRAY_TASK_ID} \
	-O $FOLDER/08_genotypeVCF/Chr${SLURM_ARRAY_TASK_ID}.vcf.gz \
	--tmp-dir $FOLDER/08_genotypeVCF/tmp
fi
}
