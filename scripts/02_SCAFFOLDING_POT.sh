#!/bin/bash

#SBATCH     --job-name=POTSPA
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-30
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load python/3.10.0
module load spades/4.2.0

# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config.csv

# Sacar los nombres de cada muestra a partir del ID del array
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# Llegar al directorio donde están las secuencias de interés
input_dirname="${sample_name}_clean"
cd ../proyectos/plastisphe/jmvlazar/POT/01_CLEANING/results/${input_dirname} || exit 1

# Definir el nombre de los inputs y el output
fw_paired="${sample_name}_knead_paired_1.fastq.gz"
rv_paired="${sample_name}_knead_paired_2.fastq.gz"
fw_unmatched="${sample_name}_knead_unmatched_1.fastq.gz"
rv_unmatched="${sample_name}_knead_unmatched_2.fastq.gz"
output_dir="${sample_name}_scaffolds"

# Chequear que exista el directorio en el que almacenar el output
if [ ! -d "../../../02_SCAFFOLDING/${output_dir}" ]; then
    mkdir ../../../02_SCAFFOLDING/${output_dir}
fi


# Y ya correr metaspades
if [ ! -f "../../../02_SCAFFOLDING/${output_dir}/finish_check.txt" ]; then
../../../../../../../../usr/local/spades/4.2.0/bin/spades.py --meta -t 64 --pe1-1 ${fw_paired} --pe1-2 ${rv_paired} --pe1-s ${fw_unmatched} --pe1-s ${rv_unmatched} -o ../../../02_SCAFFOLDING/${output_dir}
touch finish_check.txt
fi

cd ../../../02_SCAFFOLDING/${output_dir} || exit 1

mv contigs.fasta ${sample_name}_contigs.fasta

#/home/proyectos/plastisphe/jmvlazar/APM/01_CLEANING/results/S07B_clean
# sbatch -A plastisphe_serv -p cccmd 02_SCAFFOLDING_POT.sh --constraint=cibeles2
#sbatch -A plastisphe_serv -p cccmd 02_SCAFFOLDING_POT.sh --constraint=cibeles2
