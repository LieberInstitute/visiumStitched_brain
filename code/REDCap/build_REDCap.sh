#!/bin/bash
#SBATCH --job-name=REDCap
#SBATCH --error=logs/%x_%j.err
#SBATCH --output=logs/%x_%j.out

set -e
echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Hostname: ${SLURM_NODENAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"
date
module load conda_R/4.4
module list
Rscript /dcs05/lieber/lcolladotor/visiumStitched_LIBD1070/LS_visiumStitched/code/REDCap/REDCap.R
