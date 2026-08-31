#!/bin/bash

#SBATCH     --job-name=POTMUL
#SBATCH     --mem=196G
#SBATCH     --cpus-per-task=64
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END
#SBATCH     --ntasks=1
#SBATCH     --array=1-30

module load semibin/2.2.1
module load bowtie2/2.5.4
module load samtools/1.16.1
module load concoct/1.1.0

config=slurm_configs/POT_slurm_config2.csv

mapfile -t SAMPLES_TO_PROCESS < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
mapfile -t sample_type < <(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)

# If I were to access the contents of sample_type this way I would get all of the hits and would need to filter out all but the first
#echo ${sample_type[@]}
#sample_type=${sample_type[1]}
# However, this way it just outputs the first element, which is the one we want to use
echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample type is ${sample_type} and it encapsulates ${SAMPLES_TO_PROCESS[@]}"

### SEMBIN2
cd ../proyectos/plastisphe/jmvlazar/POT/04_BINNING/semibin || exit 1

if [ ! -d "$sample_type" ]; then
  mkdir $sample_type
fi

contig_files=()

for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
    # Pasar al directorio de los contigs
    contig_subdir="${sample_name}_scaffolds"
    cd ../../02_SCAFFOLDING/${contig_subdir}
    contig="${PWD}/${sample_name}_contigs.fasta"
    contig_files+=($contig)
    # Back to the output directory to begin anew
    cd ../../04_BINNING/semibin
done

#echo ${contig_files[@]}

# We now go into the sample type directory to begin sample type specific operations
cd $sample_type || exit 1

if [ ! -f "concatenated_fasta/concatenated.fa.gz" ]; then
SemiBin2 concatenate_fasta --input-fasta ${contig_files[@]} --output concatenated_fasta
fi

# Sadly, the contig-read maps we had before are no longer usable, as the source (the contig file)
# has changed. So we need to re-map them again for these new contig files :(
# (on the positive side, we will reuse these mappings later for CONCOT)

mkdir ${sample_type}_maps
concatenated_contigs="${PWD}/concatenated_fasta/concatenated.fa.gz"
cd ../../../01_CLEANING/results || exit 1

for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
  # Get the read files
  reads_file1="${PWD}/${sample_name}_clean/${sample_name}_knead_paired_1.fastq.gz"
  reads_file2="${PWD}/${sample_name}_clean/${sample_name}_knead_paired_2.fastq.gz"
  reads_file3="${PWD}/${sample_name}_clean/${sample_name}_unmatched_cat.fastq.gz"
  # Index and alignment
  cd ../../04_BINNING/semibin
  index_name="${sample_type}/${sample_type}_maps/${sample_name}_index"
  if [ ! -f "${sample_type}/${sample_type}_maps/${sample_name}_build_check.txt" ]; then
    bowtie2-build --threads 64 ${concatenated_contigs} ${index_name}
    touch ${sample_type}/${sample_type}_maps/${sample_name}_build_check.txt
  fi
  result_dir="${sample_type}/${sample_type}_maps/${sample_name}_conc_map.sam"
  if [ ! -f "${sample_type}/${sample_type}_maps/${sample_name}_map_check.txt" ]; then
    bowtie2 --threads 64 -x ${index_name} -1 ${reads_file1}  -2 ${reads_file2}  -U ${reads_file3} -S ${result_dir}
    touch ${sample_type}/${sample_type}_maps/${sample_name}_map_check.txt
  fi
  # Convert to .bam, order and index
  sam_fname="${sample_type}/${sample_type}_maps/${sample_name}_conc_map.sam"
  bam_fname="${sample_type}/${sample_type}_maps/${sample_name}_conc_map.bam"
  bam_sorted_fname="${sample_type}/${sample_type}_maps/${sample_name}_conc_map_sorted.bam"
  bam_index_fname="${sample_type}/${sample_type}_maps/${sample_name}_conc_map_index.bai"

  if [ ! -f "${sample_type}/${sample_type}_maps/${sample_name}_view_check.txt" ]; then
    samtools view -S -b ${sam_fname} > ${bam_fname}
    touch ${sample_type}/${sample_type}_maps/${sample_name}_view_check.txt
  fi
  if [ ! -f "${sample_type}/${sample_type}_maps/${sample_name}_sort_check.txt" ]; then
    samtools sort ${bam_fname} -o ${bam_sorted_fname}
    touch ${sample_type}/${sample_type}_maps/${sample_name}_sort_check.txt
  fi
  if [ ! -f "${sample_type}/${sample_type}_maps/${sample_name}_index_check.txt" ]; then
    samtools index ${bam_sorted_fname} -o ${bam_index_fname}
    touch ${sample_type}/${sample_type}_maps/${sample_name}_index_check.txt
  fi
  # Go back to the reads directory
  cd ../../01_CLEANING/results
done

# Now let's get all the new .bam files sorted
cd ../../04_BINNING/semibin/${sample_type}/${sample_type}_maps || exit 1
bam_files=()

for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
    bam_fname="${PWD}/${sample_name}_conc_map_sorted.bam"
    bam_files+=($bam_fname)
done
#echo ${bam_files[@]}

# I won't run Semibin itself in this script. I want to run it in Multi-sample mode,
# but said mode can actually be parallelized after an initial mandatory "all samples at once"
# (aka, the way this script was conceived) step. So only said step will be run in this script, leaving
# the rest of Semibin for its own dedicated parallelized run.

cd .. # go back to the semibin/sample_type folder
if [ ! -f "multi_output/samples/${sample_name}_contigs/data.csv" ]; then
  SemiBin2 generate_sequence_features_multi -i concatenated_fasta/concatenated.fa.gz -b ${bam_files[@]} -o multi_output
fi

### CONCOCT
# Concoct usually takes several previous steps that make it quite cumbersome to use.
# But, thankfully, many of those steps are shared with semibin, so we can reuse many of its
# intermediate objects to run concoct
cd ../../concoct || exit 1

if [ ! -d "$sample_type" ]; then
  mkdir $sample_type
fi
cd $sample_type

# the concoct documentation does not specify whether it works with .gz files, so I will decompress before just in case
gzip -dk ${concatenated_contigs}

# This should only run the first time. I'm copying everything because semibin does use the bamfiles
if [ ! -f "${sample_type}_maps/${sample_type}_move_check.txt" ]; then
  mkdir ${sample_type}_maps
  cd ${sample_type}_maps
  # First let's move the .bam files, both the sorted and unsorted ones
  cp -avr ../../../semibin/${sample_type}/${sample_type}_maps/*.bam .
  # Let's get rid of the unsorted ones and rename the sorted ones
  for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
    mv ${sample_name}_conc_map_sorted.bam ${sample_name}.bam
  done
  # Same thing for the indexed files
  cp ../../../semibin/${sample_type}/${sample_type}_maps/*.bai .
  for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
    mv ${sample_name}_conc_map_index.bai ${sample_name}.bam.bai
  done
  touch ${sample_type}_maps/${sample_type}_move_check.txt
fi


# Concoct usually takes several previous steps that make it quite cumbersome to use.
# But, thankfully, many of those steps are shared with semibin, so we can reuse many of its
# intermediate objects to run concoct

cd ${sample_type}_maps
bam_files=()
for sample_name in "${SAMPLES_TO_PROCESS[@]}"; do
    bam_fname="${PWD}/${sample_name}.bam"
    bam_files+=($bam_fname)
done

cd ../..
echo $PWD

if [ ! -s "contigs_10K.fa" ]; then
../../../../../../../../usr/local/concoct/1.1.0/bin/cut_up_fasta.py ../semibin/${sample_type}/concatenated_fasta/concatenated.fa -c 10000 -o 0 --merge_last -b ${sample_type}/${sample_type}_contigs_10K.bed > ${sample_type}/${sample_type}_contigs_10K.fa
fi

if [ ! -s "coverage_table.tsv" ]; then
../../../../../../../../usr/local/concoct/1.1.0/bin/concoct_coverage_table.py ${sample_type}/${sample_type}_contigs_10K.bed ${bam_files} > ${sample_type}/${sample_type}_coverage_table.tsv
fi

if [ ! -f "concoct_output/finish_check.txt" ]; then
concoct -t 64 --composition_file ${sample_type}/${sample_type}_contigs_10K.fa --coverage_file ${sample_type}/${sample_type}_coverage_table.tsv -b ${sample_type}/concoct_output/
touch ${sample_type}/concoct_output/finish_check.txt
fi

if [ ! -s "concoct_output/clustering_merged.csv" ]; then
../../../../../../../../usr/local/concoct/1.1.0/bin/merge_cutup_clustering.py ${sample_type}/concoct_output/clustering_gt1000.csv > ${sample_type}/concoct_output/clustering_merged.csv
fi

if [ ! -d "${sample_type}/concoct_output/fasta_bins" ]; then
  mkdir "${sample_type}/concoct_output/fasta_bins"
fi

../../../../../../../../usr/local/concoct/1.1.0/bin/extract_fasta_bins.py ../semibin/${sample_type}/concatenated_fasta/concatenated.fa ${sample_type}/concoct_output/clustering_merged.csv --output_path ${sample_type}/concoct_output/fasta_bins

echo "Everything finished"
#sbatch -A plastisphe_serv -p cccmd 04b_BINNING_MULTIPLE_SAMPLES_POT.sh --constraint=cibeles2
