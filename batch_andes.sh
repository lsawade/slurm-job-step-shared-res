#!/bin/bash
#SBATCH -t00:05:00
#SBATCH -A GEO111
#SBATCH -p gpu
#SBATCH -N 2
#SBATCH -n 4
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


module load cuda/11.0.2

my_srun() {
    # $1 is the hostfile
    # $2 is the number of tasks/gpus
    export SLURM_HOSTFILE="$1"
    srun -n $2 --gpus=$2 --cpus-per-task=1 --gpus-per-task=1 --distribution=arbitrary script.sh 
}

# Writing host lists in cyclicly
cyclic() {

    scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2a.cyclic.list
    scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2b.cyclic.list

    my_srun host2a.cyclic.list 2 > cyclic.2a.out 2>&1 &
    my_srun host2b.cyclic.list 2 > cyclic.2b.out 2>&1 &
    wait
}


# Writing host files in block
block() {

    scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 > host1.block.list
    scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 > host3.block.list
    scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host3.block.list
    scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host3.block.list

    my_srun host1.block.list 1 > block.1.out 2>&1 &
    my_srun host3.block.list 2 > block.3.out 2>&1 &
    wait

}

block
cyclic
