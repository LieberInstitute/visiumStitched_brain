#!/bin/bash
#SBATCH -p shared
#SBATCH --mem=5G
#SBATCH --job-name=01_compare
#SBATCH -c 1
#SBATCH -t 1:00:00
#SBATCH -o ../../processed-data/06_array_coordinates/01_compare.log
#SBATCH -e ../../processed-data/06_array_coordinates/01_compare.log

set -e

echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Node name: ${HOSTNAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"

module load conda_R/4.4

## List current modules for reproducibility
module list

Rscript 01_compare.R

echo "**** Job ends ****"
date

## This script was made using slurmjobs version 1.2.2
## available from http://research.libd.org/slurmjobs/
