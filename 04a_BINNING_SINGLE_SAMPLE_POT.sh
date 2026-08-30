#!/bin/bash

#SBATCH     --job-name=BINSSP
#SBATCH     --ntasks=1
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-30
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load python/3.10.0
#module load perl/5.36.1
module load metabat2/2.12.1
#module load maxbin2/2.2.7
module load comebin/1.0.4

# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config1-3.csv

# Sacar los nombres de cada muestra a partir del ID del array
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# Ir al directorio con las reads ordenadas
map_dir="${sample_name}_maps"
cd ../proyectos/plastisphe/jmvlazar/POT/03_MAPPING/maps/${map_dir}
# Solo necesitaremos el archivo indexado Y EL DIRECTORIO DEL ORDENADO (?)
#bam_sorted="${PWD}/${sample_name}_map_sorted.bam"
bam_sorted_dir=$PWD

if [ -f "${sample_name}_map.bam" ]; then #this is a load of horseshit sponsored by comebin
  rm ${sample_name}_map.bam
fi
#bam_indexed="${PWD}/${sample_name}_map_index.bai"
bam_indexed="${PWD}/${sample_name}_map_sorted.bam"
# Pasar al directorio de los contigs
contigs_subdir="${sample_name}_scaffolds"
cd ../../../02_SCAFFOLDING/${contigs_subdir}
contigs="${PWD}/${sample_name}_contigs.fasta"
# Y ya ir al directorio de los outputs
if [ ! -d "../../04_BINNING/metabat2" ]; then
  mkdir ../../04_BINNING/metabat2
fi

cd ../../04_BINNING/metabat2
### METABAT2
# Generate the directory and file names that will be used for METABAT2 related operations
metabat_dir="${sample_name}_metabat"
depth_res="${sample_name}_depth.txt"
bins_dir="${sample_name}_metabat_bins"

# Generate a folder in which to keep the results
if [ ! -d "$metabat_dir" ]; then
  mkdir $metabat_dir
  mkdir $metabat_dir/$bins_dir
fi
cd $metabat_dir
echo $PWD

# Generate the depth table
if [ ! -f "$depth_res" ]; then
echo "BEGINNING JGI SUMMARIZE"
jgi_summarize_bam_contig_depths --outputDepth $depth_res --referenceFasta $contigs $bam_indexed
echo "FINISHED JGI SUMMARIZE"
depth_res="${PWD}/${depth_res}" # storing the absolute path now to facilitate reusing this depth file
else
echo "jgi summarized already finished"
fi
# Run METABAT2
#if [ ! -f  "$bins_dir/finish_check.txt" ]; then
cd $bins_dir
echo "BEGINNING METABAT2"
metabat2 -i $contigs -a $depth_res -o $bins_dir
echo "FINISHED METABAT2"
touch finish_check.txt
cd ..
#else
#echo "metabat2 already finished"
#fi

### MAXBIN
# Generate the directory and file names that will be used for MAXBIN related operations
maxbin_dir="${sample_name}_maxbin"
bins_dir="${sample_name}_maxbin_bins" # I'm rewriting this variable!

# Folder for results
echo $PWD
if [ ! -d "../../maxbin2" ]; then
  mkdir ../../maxbin2
fi
cd ../../maxbin2
echo $PWD

if [ ! -d "$maxbin_dir" ]; then
  mkdir $maxbin_dir
  mkdir $maxbin_dir/$bins_dir
  #bins_dir="${PWD}/${bins_dir}" #Left in just in case
fi
cd $maxbin_dir
echo $PWD

# Run MaxBIN itself. We do not need a previous to generate the depth table because we can reuse the one created by jgi_summarize_bam_contig_depths!
#if [ ! -f  "$bins_dir/finish_check.txt" ]; then
#echo "BEGINNING MAXBIN"
#../../../../../../../../usr/local/semibin/2.2.1/bin/run_MaxBin.pl -thread 32 -contig $contigs -out $bins_dir -abund $depth_res
#echo "FINISHED MAXBIN"
#cd $bins_dir
#touch finish_check.txt
#cd ..
#else
#echo "maxbin2 already finished"
#fi

### COMEbin
# this tool runs really weirdly so a few things need to be changed
# first, instead of providing the sorted .bam files directly, it asks for the "bam directory"
# Said "bam directory" contains the results of running samtools sort

# Mind you, COMEbin asks for the bam directory while only looking for the results of samtools sort,
# so if the directory also contains the another .bam file (such as for example the result of running
# samtools view (which you need to do beforehand!) (who wrote this??)) it will just fail

# COMEbin directory and file names
comebin_dir="${sample_name}_comebin"
bins_dir="${sample_name}_comebin_bins" # I'm rewriting this variable!

echo $PWD
if [ ! -d "../../comebin" ]; then
  mkdir ../../comebin
fi
cd ../../comebin
echo $PWD

if [ ! -d "$comebin_dir" ]; then
  mkdir $comebin_dir
  mkdir $comebin_dir/$bins_dir
  #bins_dir="${PWD}/${bins_dir}" #Left in just in case
fi
cd $comebin_dir
echo $PWD

# There is one issue: in the .bam directory there are two .bam files, the unsorted and the sorted file. Either the unsorted one gets deleted or the sorted one moves around.
#if [ ! -f  "$bins_dir/finish_check.txt" ]; then
echo "BEGINNING COMEBIN"
bash ../../../../../../../../usr/local/comebin/1.0.4/bin/run_comebin.sh -a ${contigs} -o ${bins_dir} -p ${bam_sorted_dir} -t 64
echo "FINISHED COMEBIN"
cd $bins_dir
touch finish_check.txt
cd ..
#else
#echo "comebin already finished"
#fi

#sbatch -A plastisphe_serv -p cccmd 04a_BINNING_SINGLE_SAMPLE_POT.sh --constraint=cibeles2
