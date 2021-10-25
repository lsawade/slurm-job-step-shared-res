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

my_srun() {
  export SLURM_HOSTFILE="$1"
  srun -n 6 --gpus=6 --cpus-per-task=1 --gpus-per-task=1 --distribution=arbitrary script.sh 
}


# Writing host lists in cyclicly
cyclic() {    
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host1.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host1.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host2.cyclic.list

     my_srun host1.cyclic.list > cyclic.1.out 2>&1 &
     my_srun host2.cyclic.list > cyclic.2.out 2>&1 &
     wait
}


# Writinng host files in block
block() {
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 > host1.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -1 >> host1.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host1.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host1.block.list

     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 > host2.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | tail -1 >> host2.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.block.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -2 | tail -1 >> host2.block.list

     my_srun host1.block.list > block.1.out 2>&1 &
     my_srun host2.block.list > block.2.out 2>&1 &
     wait

}

block
cyclic
