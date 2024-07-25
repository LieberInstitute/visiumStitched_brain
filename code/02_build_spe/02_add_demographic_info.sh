#!/bin/bash
#SBATCH --mem=10G
#SBATCH --job-name=add_demographic_info
#SBATCH --error=/dcs04/lieber/marmaypag/spatialDLPFC_mdd_bpd_LIBD4100/spatialDLPFC_mdd_bpd/code/02_build_spe/logs/%x_%j.err
#SBATCH --output=/dcs04/lieber/marmaypag/spatialDLPFC_mdd_bpd_LIBD4100/spatialDLPFC_mdd_bpd/code/02_build_spe/logs/%x_%j.out
set -e
echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Hostname: ${SLURM_NODENAME}"
echo "Node memory requested: ${SLURM_MEM_PER_NODE}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"
date
module load conda_R/devel
module list
Rscript /dcs04/lieber/marmaypag/spatialDLPFC_mdd_bpd_LIBD4100/spatialDLPFC_mdd_bpd/code/02_build_spe/02_add_demographic_info.r
