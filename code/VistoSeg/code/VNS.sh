#!/bin/bash
#$ -cwd
#$ -l bluejay,mem_free=20G,h_vmem=20G,h_fsize=100G
#$ -pe local 5
#$ -o /dcs04/lieber/marmaypag/spatialdACC_LIBD4125/spatialdACC/code/VistoSeg/code/logs/VNS.$TASK_ID.txt
#$ -e /dcs04/lieber/marmaypag/spatialdACC_LIBD4125/spatialdACC/code/VistoSeg/code/logs/VNS.$TASK_ID.txt
#$ -m e
#$ -M ryan.miller@libd.org
#$ -t 1-5
a#$ -tc 5

echo "**** Job starts ****"
date


echo "**** JHPCE info ****"
echo "User: ${USER}"
echo "Job id: ${JOB_ID}"
echo "Job name: ${JOB_NAME}"
echo "Hostname: ${HOSTNAME}"
echo "Task id: ${SGE_TASK_ID}"
echo "****"
echo "Sample id: $(cat /dcs04/lieber/marmaypag/spatialdACC_LIBD4125/spatialdACC/code/VistoSeg/code/ALLsamples.txt | awk '{print $1}' | awk "NR==${SGE_TASK_ID}") "
echo "****"

module load matlab/R2019a

toolbox='/dcs04/lieber/marmaypag/spatialdACC_LIBD4125/spatialdACC/code/VistoSeg/code'
fname=$(cat /dcs04/lieber/marmaypag/spatialdACC_LIBD4125/spatialdACC/code/VistoSeg/code/ALLsamples.txt | awk '{print $1}' | awk "NR==${SGE_TASK_ID}")

matlab -nodesktop -nosplash -nojvm -r "addpath(genpath('$toolbox')), VNS('$fname',5)"

echo "**** Job ends ****"
date
