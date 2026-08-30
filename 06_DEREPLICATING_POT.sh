#!/bin/bash
#SBATCH     --job-name=drePSs
#SBATCH     --ntasks=1
#SBATCH     --mem=96G
#SBATCH     --cpus-per-task=32
#SBATCH     --array=1-24
#SBACTH     --mail-user juan.valenzuela@uam.es
#SBATCH     --mail-type END

module load binette/1.2.1 #dRep está aquí

# Definir el archivo de configuración
config=slurm_configs/POT_slurm_config5.csv

# Sacar los nombres de cada muestra a partir del ID del array
sample_name=$(awk -F ',' -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

echo "This is array task ${SLURM_ARRAY_TASK_ID}, the sample name is ${sample_name}"

# Llegar al directorio donde estarán las secuencias de interés
cd ../proyectos/plastisphe/jmvlazar/POT/06_DEREPLICATED || exit 1

# Chequear que exista el directorio en el que almacenar el output
if [ ! -d "${sample_name}_dereplicated" ]; then
    mkdir ${sample_name}_dereplicated
fi

# Conseguir los resultados de CheckM2
# Por cómo está configurada la instalación de checkM, dRep fallará de entrada por no estar instalado
# checkM en el modulo de binette. Pero, en realidad no hace falta que corra checkM, ya que checkM (checkM2 ciertamente, pero el output es el mismo)
# ya ha sido corrido por binette antes. Basta con acceder a esos resultados y quedarnos con lo que queremos
if [ ! -f "${sample_name}_dereplicated/checked_check.txt" ]; then
    awk -F '\t' '{OFS=",";print $5,$6,$1}' ../05_AVERAGING/${sample_name}_binetted/${sample_name}_binette_out/final_bins_quality_reports.tsv > ${sample_name}_dereplicated/checkm2_info_temp.csv # get from the final_bins_quality_reports the info we need
    sed -i 's/$/\.fa/g' ${sample_name}_dereplicated/checkm2_info_temp.csv # add the missing termination to eol, including the column name
    sed -i '1s/name.fa/genome/' ${sample_name}_dereplicated/checkm2_info_temp.csv #fix the name.fa column name to its defintive format (genome)
    awk -F ',' '{OFS=",";print $3,$1,$2}' ${sample_name}_dereplicated/checkm2_info_temp.csv > ${sample_name}_dereplicated/checkm2_info.csv #hacky as shit, but reorder columns to mimic dRep desired formatting
    touch ${sample_name}_dereplicated/checked_check.txt
fi

# Correr dREP
if [ ! -f "${sample_name}_dereplicated/dereplicate_check.txt" ]; then
    dRep dereplicate ${sample_name}_dereplicated -p 32 -g ../../POT/05_AVERAGING/${sample_name}_binetted/${sample_name}_binette_out/final_bins/*.fa --genomeInfo ${sample_name}_dereplicated/checkm2_info.csv
    touch ${sample_name}_dereplicated/dereplicate_check.txt
fi

#sbatch -A plastisphe_serv -p cccmd 06_DEREPLICATING_POT.sh --constraint=cibeles2
