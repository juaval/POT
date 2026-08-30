#!/bin/bash

#SBATCH     --job-name=Sems23
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=32
#SBATCH     --array=1-18
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load semibin/2.2.1

# Remember to change the array number based on the amount of samples being processed at once!!
config=slurm_configs/POT_slurm_config_semibin1.csv # This config file has to change on a sample type per sample type basis!

sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
mapfile -t sample_type < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)


"This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# First move into a previous step folder in which the contigs to use are found
cd ../proyectos/plastisphe/jmvlazar/POT/02_SCAFFOLDING/${sample_name}_scaffolds || exit 1
contig="${PWD}/${sample_name}_contigs.fasta"
cd ../../04_BINNING/semibin/$sample_type/multi_output || exit 1

# Let's start the training itself
SemiBin2 train_self --data samples/${sample_name}_contigs/data.csv --data-split samples/${sample_name}_contigs/data_split.csv --output multi_output/${sample_name}_model -t 32

# Binning
SemiBin2 bin_short -i ${contig} --model multi_output/${sample_name}_model/model.pt --data samples/${sample_name}_contigs/data.csv -o final_bins/${sample_name}_final_bins

# And done!
#sbatch -A plastisphe_serv -p cccmd 04c_SEMIBIN_PARALLEL_POT.sh --constraint=cibeles2

#/home/proyectos/plastisphe/jmvlazar/POT/04_BINNING/semibin/materbi1/multi_output/samples/S13_contigs
