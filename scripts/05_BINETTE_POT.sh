#!/bin/bash

#SBATCH     --job-name=BntPOT
#SBATCH     --ntasks=1
#SBATCH     --mem=128G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-30
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load binette/1.2.1
#module load binette/1.0.4

config=slurm_configs/POT_slurm_config.csv

sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
mapfile -t sample_type < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample type is ${sample_type} and the sample name is ${sample_name}"

# First get the contigs to use
cd ../proyectos/plastisphe/jmvlazar/POT/02_SCAFFOLDING/${sample_name}_scaffolds || exit 1
contigs="${PWD}/${sample_name}_contigs.fasta"
cd ../../04_BINNING || exit 1

# Next go to the metabat2 folder and get its bins
cd metabat2/${sample_name}_metabat/${sample_name}_metabat_bins
metabat_bins=$PWD
# Repeat with maxbin2
cd ../../../maxbin2/${sample_name}_maxbin #/${sample_name}_maxbin_bins #there's actually nothing within that last folder
#cd ../../../maxbin2/${sample_name}_maxbin #this one is missing one folder backwards
# Mind you that maxbin2 results are named used the .fasta format, while binette expects the .fa termination instead.
# We first have to fix it
for i in *.fasta; do mv $i ${i/.fasta/.fa};done
maxbin_bins=$PWD
# comebin
#cd ../../../comebin/${sample_name}_comebin/${sample_name}_comebin_bins/comebin_res/comebin_res_bins
cd ../../comebin/${sample_name}_comebin/${sample_name}_comebin_bins/comebin_res/comebin_res_bins
comebin_bins=$PWD
# semibin
cd ../../../../../semibin/${sample_type}/multi_output/final_bins/${sample_name}_final_bins/output_bins # these ones are actually compressed, just to suffer
semibin_bins=$PWD
# concoct
cd ../../../../../../concoct/${sample_type}/concoct_output/fasta_bins/${sample_name}
concoct_bins=$PWD

# Now everything should be ready to just run. So let's go back to the binette folder in question and try
cd ../../../../../../05_AVERAGING/


if [ ! -d "${sample_name}_binetted" ]; then
    mkdir "${sample_name}_binetted"
fi
cd ${sample_name}_binetted

binette --bin_dirs ${metabat_bins} ${maxbin_bins} ${comebin_bins} ${semibin_bins} ${concoct_bins}  --checkm2_db ../../../../../../../usr/local/BBDD/checkm2/CheckM2_database/uniref100.KO.1.dmnd -c ${contigs} -t 64 -o ${sample_name}_binette_out

#sbatch -A plastisphe_serv -p cccmd 05_BINETTE_POT.sh --constraint=cibeles2
#/home/proyectos/plastisphe/jmvlazar/APM/05_AVERAGING/S01B_binetted
# for i in *.txt; do mv $i ${i/.txt/};done
# for i in *.fasta; do mv $i ${i/.fasta/.fa};done
