#!/bin/bash

#SBATCH     --job-name=CONFIX
#SBATCH     --ntasks=1
#SBATCH     --mem=24G
#SBATCH     --cpus-per-task=1
#SBATCH     --array=1-10
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load python/3.10.0

# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config2.csv

mapfile -t SAMPLES_TO_PROCESS < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
mapfile -t sample_type < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)


echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample type is ${sample_type} and it encapsulates ${SAMPLES_TO_PROCESS[@]}"

# Save the location of the python script???
python_script="${PWD}/concoct_fix.py"

# Go to the CONCOCT results folder of the sample in question
cd ../proyectos/plastisphe/jmvlazar/POT/04_BINNING/concoct/${sample_type}/concoct_output/fasta_bins
echo $PWD

#if [ ! -d "${sample}"]
# Run the python script
python ${python_script} # Why does this work this way but not with a relative route to the script itself????


# And done!
# sbatch -A plastisphe_serv -p cccmd 04d_CONCOCT_FIXING.sh --constraint=cibeles2
