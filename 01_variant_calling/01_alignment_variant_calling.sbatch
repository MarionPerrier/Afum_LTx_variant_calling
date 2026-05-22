#!/bin/bash
#SBATCH --job-name variantCalling
#SBATCH --partition=short
#SBATCH --array=0-32
#SBATCH --mem=48G
#SBATCH --cpus-per-task=24
#SBATCH --ntasks=1
#SBATCH --output  out/alignment_%a.out.%j
#SBATCH --error   out/alignment_%a.err.%j
#SBATCH --time=03:00:00

#BEFORE RUNNING
#Remember to change path variables to your needs
#Change array to the appropriate number of samples.

# Load environment variables (unload all preexisting)
module purge

#-- Command section ------------------------
FOLDER=.
REF=~/references/gatk4/Af293_FungiDB_v68/FungiDB-68_AfumigatusAf293_Genome.fasta
IMG=docker://broadinstitute/gatk:4.6.0.0

source ~/.bashrc
source ~/mambaforge/etc/profile.d/conda.sh

SAMPLE_LIST=($(<input.list))
SAMPLE=${SAMPLE_LIST[${SLURM_ARRAY_TASK_ID}]}

mkdir -p $FOLDER/01_fastqc \
	$FOLDER/02_trim \
	$FOLDER/03_align \
	$FOLDER/04_markDuplicates \
	$FOLDER/05_baseRecalibration/02_recalibrated_bam \
	$FOLDER/06_HaplotypeCaller

############################
##	Step1: trimming of raw
##	data
##	Remove low quality sequences, adapters, and polyG
###########################

{
if [ ! -f $FOLDER/02_trim/$SAMPLE\_trim\_1.fastq.gz ]; then
mamba activate fastp

fastp \
	-i $FOLDER/00_raw/$SAMPLE\_1.fastq.gz \
	-I $FOLDER/00_raw/$SAMPLE\_2.fastq.gz \
	-o $FOLDER/02_trim/$SAMPLE\_trim\_1.fastq.gz \
	-O $FOLDER/02_trim/$SAMPLE\_trim\_2.fastq.gz \
	--detect_adapter_for_pe \
	--trim_poly_g \
	-q 20 \
	-l 30
fi
}

###########################
##	Step2: QC to
##	check the cleaning
###########################
{
if [ ! -f $FOLDER/01_fastqc/$SAMPLE\_trim\_1\_fastqc.html ]; then

mamba activate fastqc
fastqc $FOLDER/02_trim/$SAMPLE\_trim\_1.fastq.gz -t 12 -o $FOLDER/01_fastqc/.
fastqc $FOLDER/02_trim/$SAMPLE\_trim\_2.fastq.gz -t 12 -o $FOLDER/01_fastqc/.
fi
}

##########################
##	Step4: alignment against
##	reference Af293 v68 FungiDB
##########################
{
if [ ! -f $FOLDER/03_align/$SAMPLE.bam ]; then

mamba activate bwamem2

bwa-mem2 mem \
	-t 12 \
	-R $(echo "@RG\tID:$SAMPLE\tLB:$SAMPLE\tPL:ILLUMINA\tSM:$SAMPLE") \
	-o $FOLDER/03_align/$SAMPLE.sam \
	~/references/bwa_mem/Af293_fungiDB/Af293_fungiDB \
	$FOLDER/02_trim/$SAMPLE\_trim_1.fastq.gz \
	$FOLDER/02_trim/$SAMPLE\_trim_2.fastq.gz

#and convert alignment into BAM
mamba activate samtools
samtools view -bo $FOLDER/03_align/$SAMPLE.bam $FOLDER/03_align/$SAMPLE.sam

#remove SAM, as unused.
rm $FOLDER/03_align/$SAMPLE.sam
fi
}

###########################
##	Step 5: MarkDuplicates
##	from GATK MarkDuplicatesSpark
###########################
{
if [ ! -f $FOLDER/04_markDuplicates/$SAMPLE\_markDup.bam ]; then

singularity run $IMG \
gatk MarkDuplicatesSpark \
	-I $FOLDER/03_align/$SAMPLE.bam \
	-O $FOLDER/04_markDuplicates/$SAMPLE\_markDup.bam \
	-M $FOLDER/04_markDuplicates/$SAMPLE\_markDup_metrics.txt
fi
}


###########################
##	Step 6: Base recalibration
##
###########################

#The dataset created for baseRecalibration is described in the methods section;
#I've merged the VCF files of a 300 WGS collection together. 

#now we create indexes of the reference. This will be run only once.
{
if [ ! -f ~/references/gatk4/Af293_FungiDB_v68/FungiDB-68_AfumigatusAf293_Genome.dict ]; then

singularity run $IMG \
gatk CreateSequenceDictionary -R $REF

singularity run $IMG \
samtools faidx $REF
fi
}

{
if [ ! -f $FOLDER/05_baseRecalibration/$SAMPLE\_recat_data.table ]; then
singularity run $IMG \
gatk BaseRecalibrator \
	-I $FOLDER/04_markDuplicates/$SAMPLE\_markDup.bam \
	-R $REF \
	--known-sites $FOLDER/afum_300_genomes_merged.vcf.gz \
	-O $FOLDER/05_baseRecalibration/$SAMPLE\_recat_data.table

#Now we need to apply the recalibration onto our data (If I understood correctly)
singularity run $IMG \
gatk ApplyBQSR \
	-R $REF \
	-I $FOLDER/04_markDuplicates/$SAMPLE\_markDup.bam \
	--bqsr-recal-file $FOLDER/05_baseRecalibration/$SAMPLE\_recat_data.table \
	-O $FOLDER/05_baseRecalibration/02_recalibrated_bam/$SAMPLE\_recalibrated.bam
fi
}

##########################
##	Step 7: Haplotype caller
##	now we call the variants
##########################

{
if [ ! -f $FOLDER/06_HaplotypeCaller/$SAMPLE.g.vcf.gz ]; then

singularity run $IMG \
gatk --java-options "-Xmx4g" HaplotypeCaller \
	-R $REF \
	-I $FOLDER/05_baseRecalibration/02_recalibrated_bam/$SAMPLE\_recalibrated.bam \
	-O $FOLDER/06_HaplotypeCaller/$SAMPLE.g.vcf.gz \
	-ploidy 1 \
	-ERC GVCF
fi
}
