#!/bin/bash
#SBATCH     --job-name=POTMAP
#SBATCH     --ntasks=1
#SBATCH     --mem=128G
#SBATCH     --cpus-per-task=64
#SBATCH     --array=1-30
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load bowtie2/2.5.4
module load samtools/1.16.1
module load perl/5.36.1

# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config.csv

# Sacar los nombres de cada muestra a partir del ID del array
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# Generar los correspondientes nombres de los directorios de los contigs y de las reads
contigs_subdir="${sample_name}_scaffolds"
echo $contigs_subdir
reads_subdir="${sample_name}_clean"
echo $reads_subdir

# Los directorios aun no están acabados, ya que aún queda terminar de poner la ruta completa
# Esto lo haré yendo primero a una carpeta y luego a la otra
cd ../proyectos/plastisphe/jmvlazar/POT #primero entrar en el proyecto

# contigs
cd 02_SCAFFOLDING
contigs_file="${PWD}/${contigs_subdir}/${sample_name}_contigs.fasta"
echo $contigs_file

# reads
cd ../01_CLEANING/results
reads_dir="${PWD}/${reads_subdir}"
# file1 = fw paired reads
reads_file1="${reads_dir}/${sample_name}_knead_paired_1.fastq.gz"
#file2 = rv paired reads
reads_file2="${reads_dir}/${sample_name}_knead_paired_2.fastq.gz"
#file3 = concatenated unpaired reads from both fw and rv
reads_file3="${reads_dir}/${sample_name}_unmatched_cat.fastq.gz"

if [ ! -f "$reads_file3" ]; then
    echo "Unmatched reads were in separate files, concatenating"
    cat "${reads_dir}/${sample_name}_knead_unmatched_1.fastq.gz" "${reads_dir}/${sample_name}_knead_unmatched_2.fastq.gz" > $reads_file3
    echo "Unmatched reads concatenated!"
fi

## Ahora que ya están todos los archivos necesarios listos, se puede correr bowtie2
cd ../../03_MAPPING # moverse al directorio donde iran los archivos definitivos
# El primer paso es generar un índice de los contigs
# Antes generaré el nombre que querría que tuviera el archivo
index_name="indices/${sample_name}_index"
if [ ! -f "indices/${sample_name}_finish_check.txt" ]; then
    bowtie2-build --threads 64 ${contigs_file} ${index_name}
    touch indices/${sample_name}_finish_check.txt
fi

# Luego ya se puede hacer el mapeo de reads en los contigs
result_dir="maps/${sample_name}_maps/${sample_name}_map.sam"

if [ ! -d "maps/${sample_name}_maps" ]; then
    mkdir maps/${sample_name}_maps
fi

if [ ! -f "maps/${sample_name}_maps/${sample_name}_map_check.txt" ]; then
    bowtie2 --threads 64 -x ${index_name} -1 ${reads_file1}  -2 ${reads_file2}  -U ${reads_file3} -S ${result_dir}
    touch maps/${sample_name}_maps/${sample_name}_map_check.txt
fi

# Let's move into samtools
cd maps/${sample_name}_maps

# Fnames for the files used from now on
sam_fname="${sample_name}_map.sam"
bam_fname="${sample_name}_map.bam"
bam_sorted_fname="${sample_name}_map_sorted.bam"
bam_index_fname="${sample_name}_map_index.bai"

echo "The fnames are: ${sam_fname} for the .sam, ${bam_fname} for the .bam, ${bam_sorted_fname} for the sorted and ${bam_index_fname} for the idx"
# We turn the .sam file into a .bam file
if [ ! -f "${sample_name}_view_check.txt" ]; then
    samtools view -S -b ${sam_fname} > ${bam_fname}
    touch ${sample_name}_view_check.txt
fi
# We sort the .bam
if [ ! -f "${sample_name}_sort_check.txt" ]; then
    samtools sort ${bam_fname} -o ${bam_sorted_fname}
    touch ${sample_name}_sort_check.txt
fi
# We generate its index
if [ ! -f "${sample_name}_index_check.txt" ]; then
    samtools index ${bam_sorted_fname} -o ${bam_index_fname}
    touch ${sample_name}_index_check.txt
fi

#sbatch -A plastisphe_serv -p cccmd 03_MAPPING_POT.sh --constraint=cibeles2



