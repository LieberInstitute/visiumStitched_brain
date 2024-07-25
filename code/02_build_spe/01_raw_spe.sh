#!/bin/bash
#SBATCH --mem=80G
#SBATCH --job-name=LS_build_spe
#SBATCH -o logs/raw_spe.txt


echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOBID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Hostname: ${SLURM_NODENAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"

## Load the R module
module load conda_R/

## List current modules for reproducibility
module list

## Edit with your job command
Rscript 01_raw_spe.R

echo "**** Job ends ****"
date

## This script was made using sgejobs version 0.99.1
## available from http://research.libd.org/sgejobs/