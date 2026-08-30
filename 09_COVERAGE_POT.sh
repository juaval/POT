#!/bin/bash

#SBATCH     --job-name=coverm
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-24
#SBATCH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load binette/1.2.1 #CoverM is installed here


config=slurm_configs/POT_slurm_config5.csv #config to use
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config) #get sample names

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}" #quick check for debugging purposes

# get to the wd
cd ../proyectos/plastisphe/jmvlazar/POT/09_COVERAGE || exit 1

## define the directories and files to be used by coverM
# original input files
cd ../01_CLEANING/results/${sample_name}_clean
fw_file="${PWD}/${sample_name}_knead_paired_1.fastq.gz"
rv_file="${PWD}/${sample_name}_knead_paired_2.fastq.gz"
fw_single_file="${PWD}/${sample_name}_knead_unmatched_1.fastq.gz"
rv_single_file="${PWD}/${sample_name}_knead_unmatched_2.fastq.gz"
# genomes to be compared
cd ../../../06_DEREPLICATED/${sample_name}_dereplicated/dereplicated_genomes
genomes="${PWD}"

# While we are at it, change fnames for future use
for i in *fa; do mv $i ${i/$i/${sample_name}_$i}; done

# And now coverM has everything it needs to run.
cd ../../../09_COVERAGE
if [ ! -d "${sample_name}_coverage" ]; then
mkdir "${sample_name}_coverage"
fi
cd ${sample_name}_coverage

coverm genome \
  --coupled ${fw_file} ${rv_file} \
  --single ${fw_single_file} ${rv_single_file} \
  --genome-fasta-directory ${genomes} \
  --genome-fasta-extension fa \
  -t 64 \
  -m mean relative_abundance covered_fraction \
  -o ${sample_name}_coverm_output.tsv

#sbatch -A plastisphe_serv -p cccmd 09_COVERAGE_POT.sh --constraint=cibeles2
#https://scienceparkstudygroup.github.io/ibed-bioinformatics-page/source/metagenomics/coverm.html
