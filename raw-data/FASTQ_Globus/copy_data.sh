#!/bin/bash
#SBATCH -p shared
#SBATCH --mem=2G
#SBATCH --job-name=copy_data
#SBATCH -c 1
#SBATCH -t 1:00:00
#SBATCH -o copy_data.log
#SBATCH -e copy_data.log

set -e

echo "**** Job starts ****"
date

echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Node name: ${HOSTNAME}"
echo "Task id: ${SLURM_ARRAY_TASK_ID}"

repo_dir=$(git rev-parse --show-toplevel)
capture_areas=(V13B23-283_A1 V13B23-283_C1 V13B23-283_D1)

for capture_area in ${capture_areas[@]}; do
    orig_dir=$repo_dir/raw-data/FASTQ/$capture_area
    dest_dir=$repo_dir/raw-data/FASTQ_Globus/$capture_area
    mkdir -p $dest_dir

    #   Follow symbolic links and produce a copy of the originals
    for base_name in $(ls $orig_dir); do
        src_file=$(readlink $orig_dir/$base_name)
        cp $src_file $dest_dir/
    done
done

echo "**** Job ends ****"
date

## This script was made using slurmjobs version 1.2.2
## available from http://research.libd.org/slurmjobs/
