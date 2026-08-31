# OBJECTIVE: run kneaddata on a loop for the 30 or so samples of interest
cd ../data/raw_data
dir=$PWD

for fname in *; do
    echo "Original fname: $fname"
    length=${#fname}
    # we want to keep the fname without the last character
    # AND the trailing format. As all files are .fastq.gz,
    # we need to substract 1(dot)+5(fastq)+1(dot)+2(gz)+1(last character) = 10 characters
    ((length=length-10))
    # we can also extract the file type (fw / rv) using the same logic: keep the 10th character from the back
    ((ftype=length+1))
    ftype=$(cut -c $ftype <<< $fname)
    echo "here ftype:$ftype  fname: $fname mlength: $length"
    if [ $ftype -eq 1 ];then
        rvname=${fname:0:$length}
        rvname+="2.fastq.gz"
        echo "Starting work with sample $fname"
        kneaddata --input1 $fname --input2 $rvname -db /home/pak/databases2/kneaddata_db/bowtie2-index --output ../kneaded_data --verbose -t 10 --remove-intermediate-output --run-trim-repetitive --fastqc FastQC
    fi
done

cd ../kneaded_data

for file in *; do
    echo "Compressing $file"
    gzip $file
done
