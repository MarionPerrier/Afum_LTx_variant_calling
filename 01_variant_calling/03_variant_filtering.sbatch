#!/bin/bash
#SBATCH --job-name variantFilter
#SBATCH --partition=short
#SBATCH --mem=48G
#SBATCH --cpus-per-task=24
#SBATCH --ntasks=1
#SBATCH --output  out/variantFilter_%a.out.%j
#SBATCH --error   out/variantFilter_%a.err.%j
#SBATCH --time=03:00:00

# Load environment variables (unload all preexisting)
module purge

#-- Command section ------------------------

FOLDER=.
REF=~/references/gatk4/Af293_FungiDB_v68/FungiDB-68_AfumigatusAf293_Genome.fasta
IMG=docker://broadinstitute/gatk:4.6.0.0

source ~/.bashrc
source ~/mambaforge/etc/profile.d/conda.sh

mkdir -p $FOLDER/09_SNPFilter $FOLDER/10_indelFilter $FOLDER/11_merged_snp_indel $FOLDER/12_snpAnnot

{
if [ ! -f $FOLDER/08_genotypeVCF/merged/samples.vcf.gz ]; then
mamba activate bcftools
mkdir -p $FOLDER/08_genotypeVCF/merged
bcftools concat --threads 16 -o $FOLDER/08_genotypeVCF/merged/samples.vcf.gz $FOLDER/08_genotypeVCF/*vcf.gz
tabix -f -p vcf $FOLDER/08_genotypeVCF/merged/samples.vcf.gz
fi
}

##################
##  Step 10: Filter snp!
## Keep only high confidence VCF
##################

{
if [ ! -f $FOLDER/09_SNPFilter/samples.pass.snp.vcf.gz  ]; then
#first, isolate SNP
singularity run $IMG \
gatk SelectVariants \
	-R $REF \
	-V $FOLDER/08_genotypeVCF/merged/samples.vcf.gz \
	--select-type SNP \
	-O $FOLDER/09_SNPFilter/samples.snp.vcf.gz

#Second, Filter!
singularity run $IMG \
gatk VariantFiltration \
	-V  $FOLDER/09_SNPFilter/samples.snp.vcf.gz \
	-O  $FOLDER/09_SNPFilter/samples.filter.snp.vcf.gz \
	-R $REF \
	--filter-expression "QD < 2.0" --filter-name "QD2" \
	--filter-expression "MQ < 40.0" --filter-name "MQ40" \
	--filter-expression "FS > 60.0" --filter-name "FS60" \
	--filter-expression "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
	--filter-expression "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8"

#third, you select the pass only
singularity run $IMG \
gatk SelectVariants \
	-R $REF \
	-V $FOLDER/09_SNPFilter/samples.filter.snp.vcf.gz \
	--exclude-filtered \
	-O $FOLDER/09_SNPFilter/samples.pass.snp.vcf.gz 
fi
}

######################
##	Step11: Do the same
##	With Indels
######################
{
if [ ! -f $FOLDER/10_indelFilter/samples.pass.indel.vcf.gz ]; then
#first, select only indels
singularity run $IMG \
gatk SelectVariants \
        -R $REF \
        -V $FOLDER/08_genotypeVCF/merged/samples.vcf.gz \
        --select-type INDEL \
        -O $FOLDER/10_indelFilter/samples.indel.vcf.gz


#Second, Filter!
singularity run $IMG \
gatk VariantFiltration \
        -V  $FOLDER/10_indelFilter/samples.indel.vcf.gz \
        -O  $FOLDER/10_indelFilter/samples.filter.indel.vcf.gz \
        -R $REF \
        --filter-expression "QD < 2.0" --filter-name "QD2" \
        --filter-expression "FS > 200.0" --filter-name "FS200" \
        --filter-expression "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20"

#third, you select the pass only
singularity run $IMG \
gatk SelectVariants \
	-R $REF \
	-V $FOLDER/10_indelFilter/samples.filter.indel.vcf.gz \
	--exclude-filtered \
	-O $FOLDER/10_indelFilter/samples.pass.indel.vcf.gz 
fi
}

################
##	Step 12: Merge the
##	SNP and Indels back together
################
{
if [ ! -f $FOLDER/11_merged_snp_indel/samples.pass.vcf.gz ]; then
singularity run $IMG \
gatk MergeVcfs \
	-I $FOLDER/09_SNPFilter/samples.pass.snp.vcf.gz \
	-I $FOLDER/10_indelFilter/samples.pass.indel.vcf.gz \
	-O $FOLDER/11_merged_snp_indel/samples.pass.vcf.gz 
fi
}

################
##	Step 13: Annotate
##	with SNPEff
################
mamba activate snpeff
{
if [ ! -f ~/conda_env/snpeff/share/snpeff-5.2-1/data/Af293 ]; then
#Build the database of annotation (doesn't includes the agat GFF3 -> GTF conversion using AGAT)

snpEff build \
    -gtf22 \
    -noCheckCds \
    -maxErrorRate 1 \
    -v Af293 
fi
}

#Annotate the variants
{
if [ ! -f $FOLDER/12_snpAnnot/samples.ann.vcf ]; then
snpEff Af293 \
    $FOLDER/11_merged_snp_indel/samples.pass.vcf.gz > $FOLDER/12_snpAnnot/samples.ann.vcf

#Now we split by samples
mamba activate bcftools
mkdir -p $FOLDER/12_snpAnnot/00_bySamples
bcftools +split \
    -S $FOLDER/input.split \
    -o $FOLDER/12_snpAnnot/00_bySamples \
    $FOLDER/12_snpAnnot/samples.ann.vcf
fi
}

