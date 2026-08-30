#!/bin/bash

#SBATCH     --job-name=gtdbk
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=32
#SBATCH     --array=1-24
#SBATCH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load gtdbtk/2.2.3
#module load gtdbtk/2.7.1-OPA

config=slurm_configs/POT_slurm_config5.csv #config to use
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config) #get sample names

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}" #quick check for debugging purposes

# get to the wd
cd ../proyectos/plastisphe/jmvlazar/POT/08_TAXONOMY || exit 1

# create the output directory if it doesn't exist
if [ ! -d "${sample_name}_taxonomy" ]; then
    mkdir ${sample_name}_taxonomy
    mkdir ${sample_name}_taxonomy/${sample_name}_identify
    mkdir ${sample_name}_taxonomy/${sample_name}_align
    mkdir ${sample_name}_taxonomy/${sample_name}_classified
    mkdir ${sample_name}_taxonomy/${sample_name}_mash
fi

# First step is to identify genes present in the genomes
gtdbtk identify --genome_dir ../06_DEREPLICATED/${sample_name}_dereplicated/dereplicated_genomes --out_dir ${sample_name}_taxonomy/${sample_name}_identify --extension fa --cpus 32

# Next, align the identified markers
gtdbtk align --identify_dir ${sample_name}_taxonomy/${sample_name}_identify --out_dir ${sample_name}_taxonomy/${sample_name}_align --cpus 32

# Finally, classify the genome by making the corresponding tree
gtdbtk classify --genome_dir ../06_DEREPLICATED/${sample_name}_dereplicated/dereplicated_genomes --align_dir ${sample_name}_taxonomy/${sample_name}_align --out_dir ${sample_name}_taxonomy/${sample_name}_classified -x fa --cpus 32 --mash_db ${sample_name}_taxonomy/${sample_name}_mash

#sbatch -A plastisphe_serv -p cccmd 08_TAXONOMY_POT.sh --constraint=cibeles2
#https://scienceparkstudygroup.github.io/ibed-bioinformatics-page/source/metagenomics/coverm.html
