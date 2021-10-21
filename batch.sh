#!/bin/bash
#SBATCH -t00:05:00
#SBATCH --gpus 12
#SBATCH -n 12
#SBATCH --output=mixed_gpu.txt

# The above request will ask for 3 nodes on Traverse
# because each node has 4 gpus (12 / 4 = 3)
#
# The goal is to run two Job Steps with each 6 tasks and 1 gpu per task
# on a total of 3 nodes at the same time. This means that the job steps
# have to share one node. Usually this should be possible using the
# --distribution=arbitrary option and providing a nodelist to
# slurm. That however doesn't seem to be the case on traverse
# 


module load openmpi/gcc cudatoolkit

atype=cyclic


# Writing Node lists in cyclicly
if [ "$atype" == "cyclic" ];
then
    
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host1.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host2.list

# Writing Node lists in Chunks
# DOESNT WORK AT ALL!     
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
echo "Submission 1"
srun -n 6 --cpus-per-task=1 --gpus-per-task 1 --distribution=arbitrary show_devices.sh 0 & 
sleep 2

export SLURM_HOSTFILE=host2.list
echo "Submission 2?"
srun -n 6 --cpus-per-task 1 --gpus-per-task 1 --distribution=arbitrary show_devices.sh 1 & 

echo "Pre-wait print"
wait

echo "Post-wait print""
