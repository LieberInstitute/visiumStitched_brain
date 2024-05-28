#!/bin/bash
#SBATCH --mem=80G
#SBATCH -n 8
#SBATCH --job-name=LS-spaceranger
#SBATCH -o logs/spaceranger_slurm_240523o.txt
#SBATCH --array=1-3

echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOBID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Hostname: ${SLURM_NODENAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"

## load SpaceRanger
module load spaceranger/3.0.0

## List current modules for reproducibility
module list

## Locate file
SAMPLE=$(awk "NR==${SLURM_ARRAY_TASK_ID}" sample-list.txt)
echo "Processing sample ${SAMPLE}"
date

## Get slide and area
SLIDE=$(echo ${SAMPLE} | cut -d "_" -f 1)
CAPTUREAREA=$(echo ${SAMPLE} | cut -d "_" -f 2)
SAM=$(paste <(echo ${SLIDE}) <(echo "-") <(echo ${CAPTUREAREA}) -d '')
echo "Slide: ${SLIDE}, capture area: ${CAPTUREAREA}"

## Find FASTQ file path
FASTQPATH=$(ls -d /dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/raw-data/FASTQ/${SAMPLE}/)

## Hank from 10x Genomics recommended setting this environment
export NUMBA_NUM_THREADS=1

## Run SpaceRanger
spaceranger count \
    --id=${SAMPLE} \
    --transcriptome=/dcs04/lieber/lcolladotor/annotationFiles_LIBD001/10x/refdata-gex-GRCh38-2024-A \
    --fastqs=${FASTQPATH}\
    --image=/dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/processed-data/images/capture-areas/${SAMPLE}.tif \
    --slide=${SLIDE} \
    --area=${CAPTUREAREA} \
    --loupe-alignment=/dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/processed-data/images/loupe/${SAM}.json \
    --jobmode=local \
    --localcores=8 \
    --localmem=64 \
    --create-bam=false
#    --r1-length=26

## Move output
echo "Moving results to new location"
date
mkdir -p /dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/processed-data/01_spaceranger/
mv ${SAMPLE} /dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/processed-data/01_spaceranger/

echo "**** Job ends ****"
date

## This script was made using sgejobs version 0.99.1
## available from http://research.libd.org/sgejobs/
