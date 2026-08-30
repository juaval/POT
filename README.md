# POT
Repository for the various scripts used in the analysis of the paper POT, as well as a brief explanation of the pipeline used.

## Software and libraries used
-  Python 3.10.0
-  Perl 5.36.1
-  Kneaddata 0.12.1
-  fastq_pair 1.0.0
-  Spades 4.2.0
-  bowtie2 2.5.4
-  samtools 1.16.1
-  metabat2 2.12.1
-  maxbin2 2.2.7
-  comebin 1.0.4
-  semibin 2.2.1
-  concoct 1.1.0
-  binette 1.2.1
-  dRep 3.7.1
-  coverM 0.8.0
-  CheckM2 1.1.0

## Pipeline explanation
### Raw sequence trimming and quality filtering
1.  Kneaddata is first used to perform some basic quality control on the input sequences. It takes the paired read files as provided by the sequencing company and, through tools such as trimmomatic, bowtie2, fastqc and trf removes their primers, removes overrepresented sequences, tandem repeats, reads which do not have enough quality using a sliding window and reads which are flagged as belonging to a contaminants database. It outputs eight fastq.gz files, depending on how it has flagged the reads within. I only use the reads which have passed the filtering and quality filtering step going forward, whether they are paired or unpaired.
2.  (optional) In a few occasions, kneaddata does not work properly and generates paired files which have an unequal number of reads in them. In those few cases I ran fastq_pair on them manually. fastq_pair takes in two supposedly paired end files and separates the reads of the files which match from those that do not match (e.g., if the fw file had 1004 reads and the rv file had 1000 reads, it would generate three files: a new fw file with the 1000 matching reads, a ne-named rv file with its original 1000 reads and a new fw-unpaired reads file with the unmatched 4.). I would later concatenate the newly generated unmatched files with their corresponding, original unmatched reads files (following the last example, the newly generated fw-unpaired file with 4 reads would be concatenated using cat with the fw unmatched reads file originally produced by kneaddata)
### Generating scaffolds and mapping the reads to said scaffolds
3.  SPAdes, in metagenomes mode, is used to generate scaffolds that will be used going forward.
