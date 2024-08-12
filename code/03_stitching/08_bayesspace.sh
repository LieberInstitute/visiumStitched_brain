#!/bin/bash
#SBATCH -p shared
#SBATCH --mem=20G
#SBATCH --job-name=08_bayesspace
#SBATCH -c 1
#SBATCH -t 8:00:00
#SBATCH -o /dev/null
#SBATCH -e /dev/null
#SBATCH --array=2-20%10

## Define loops and appropriately subset each variable for the array task ID
all_stitched_var=(stitched unstitched)
stitched_var=${all_stitched_var[$(( $SLURM_ARRAY_TASK_ID / 10 % 2 ))]}

all_gene_var=(HVG SVG)
gene_var=${all_gene_var[$(( $SLURM_ARRAY_TASK_ID / 5 % 2 ))]}

all_k=(2 4 8 16 24)
k=${all_k[$(( $SLURM_ARRAY_TASK_ID / 1 % 5 ))]}

## Explicitly pipe script output to a log
log_path=../../processed-data/03_stitching/logs/08_bayesspace_${stitched_var}_${gene_var}_${k}_${SLURM_ARRAY_TASK_ID}.txt

{
set -e

echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Node name: ${HOSTNAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"

## Load the R module
module load conda_R/4.3

## List current modules for reproducibility
module list

## Edit with your job command
Rscript 08_bayesspace.R --stitched_var ${stitched_var} --gene_var ${gene_var} --k ${k}

echo "**** Job ends ****"
date

} > $log_path 2>&1

## This script was made using slurmjobs version 1.2.2
## available from http://research.libd.org/slurmjobs/

