#!/bin/bash

#SBATCH     --job-name=Maxpot
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-30
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load maxbin2/2.2.7


# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config.csv

# Sacar los nombres de cada muestra a partir del ID del array
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# Ir al directorio con las reads ordenadas
cd ../proyectos/plastisphe/jmvlazar/POT/03_MAPPING/maps/${sample_name}_maps
# Solo necesitaremos el archivo indexado
bam_indexed="${PWD}/${sample_name}_map_sorted.bam"
# Pasar al directorio de los contigs
cd ../../../02_SCAFFOLDING/${sample_name}_scaffolds
contigs="${PWD}/${sample_name}_contigs.fasta"
# Pillar la depth table generada previamente por metabat2
cd ../../04_BINNING/metabat2/${sample_name}_metabat
depth_res="${PWD}/${sample_name}_depth.txt"
echo $depth_res
# Ya ir al directorio de maxbin2
cd ../../maxbin2

### MAXBIN
# Generate the directory and file names that will be used for MAXBIN related operations
maxbin_dir="${sample_name}_maxbin"

if [ ! -d "$maxbin_dir" ]; then
  mkdir $maxbin_dir
  mkdir $maxbin_dir/${sample_name}_maxbin_bins
fi
cd $maxbin_dir
bins_dir="${PWD}/${sample_name}_maxbin_bins"
echo $PWD

# Run MaxBIN itself. We do not need a previous to generate the depth table because we can reuse the one created by jgi_summarize_bam_contig_depths!
echo "BEGINNING MAXBIN"
../../../../../../../../usr/local/semibin/2.2.1/bin/run_MaxBin.pl -thread 64 -contig $contigs -out $bins_dir -abund $depth_res || exit 1
echo "MAXBIN FINISHED"

#sbatch -A plastisphe_serv -p cccmd 04_MAXBIN2_POT.sh --constraint=cibeles2
