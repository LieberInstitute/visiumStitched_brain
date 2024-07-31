#!/bin/bash
#SBATCH -p shared
#SBATCH --mem=20G
#SBATCH --job-name=05_precast_unstitched
#SBATCH -c 1
#SBATCH -t 1-00:00:00
#SBATCH --array=2,4,8
#SBATCH -o ../../processed-data/03_stitching/logs/05_precast_unstitched_%a.log
#SBATCH -e ../../processed-data/03_stitching/logs/05_precast_unstitched_%a.log

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

Rscript 05_precast_unstitched.R -k $SLURM_ARRAY_TASK_ID

echo "**** Job ends ****"
date

## This script was made using slurmjobs version 1.2.2
## available from http://research.libd.org/slurmjobs/
