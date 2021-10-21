#!/bin/bash
#SBATCH -t00:05:00
#SBATCH --gpus 12
#SBATCH -n 12
#SBATCH --output=mixed_gpu.txt

module load openmpi/gcc cudatoolkit

atype=cyclic

# Writing Node lists in Chunkss
if [ "$atype" == "cyclic" ];
then

     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host2.list

elif [ "$atype" == "block" ];
then

     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 > host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host1.list

     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 > host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.list

else

    echo Task assignment "$atype" not implemented -- exiting.
    exit

fi


# Print nodelist content
echo
echo Printing hostlists
echo
echo Hosts 1
cat host1.list
echo
echo Hosts 2
cat host2.list
echo

export SLURM_HOSTFILE=host1.list
echo "Is this happening?"
srun --cpus-per-task=1 --gpus-per-task=1 --accel-bind=g,v --exact --distribution=arbitrary show_devices.sh 0 & 
sleep 2

export SLURM_HOSTFILE=host2.list
echo "Is this happening, too?"
srun --cpus-per-task=1 --gpus-per-task=1 --accel-bind=g,v --exact --distribution=arbitrary show_devices.sh 1 & 

echo "and this?"
wait

echo "and this?"
