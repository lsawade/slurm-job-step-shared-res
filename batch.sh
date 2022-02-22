#!/bin/bash
#SBATCH -t00:05:00
#SBATCH -N 2
#SBATCH -n 56
# # SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-core=1
#SBATCH --output=mixed_gpu.txt
# # SBATCH --reservation=test
#SBATCH --gres=gpu:4




# The above request will ask for 3 nodes on Traverse
# because each node has 4 gpus (12 / 4 = 3)
#
# The goal is to run two Job Steps with each 6 tasks and 1 gpu per task
# on a total of 3 nodes at the same time. This means that the job steps
# have to share one node. Usually this should be possible using the
# --distribution=arbitrary option and providing a nodelist to
# slurm.
#
# The above now seems to work. But one ***cannot*** ask for G=8 or gpus-per-task.
# SBATCH --gres=gpu:4, just make the GPUs available in the allocation and
# then the srun commands should take care of everything.
#
# It is important to note that I'm requesting 64 tasks (32 per node), but each
# task is allocation 4 cpus. This actually means 4 threads because the Power9
# CPUs have hardware threads that are explicitly available through slurm. Meaning
# the total number of tasks available per node is 128 [32 * 4]. But there are only
# 32 physical cores. When a GPU gets bound to a multiple threads on a single physical
# core there are allocation issues. Hence, We specify cpus-per-task=4, ntask-per-core=1.
# and then only so many tasks as there are available on each node!


module load openmpi/gcc cudatoolkit

my_srun() {
    # $1 is hosfile
    # $2 is task/gpu count
    export SLURM_HOSTFILE="$1"
    srun --ntasks=$2 --gpus-per-task=1 --cpus-per-task=4 --ntasks-per-core=1 --distribution=arbitrary script.sh
}

# --Ntasks-per-node=2


# Writing host lists in cyclicly
cyclic() {    
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host1.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host1.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" > host2.cyclic.list
     scontrol show hostnames "${SLURM_JOB_NODELIST}" >> host2.cyclic.list

     my_srun host1.cyclic.list 4 > cyclic.1.out 2>&1 &
     my_srun host2.cyclic.list 4 > cyclic.2.out 2>&1 &
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

     my_srun host1.block.list 6 > block.1.out 2>&1 &
     my_srun host2.block.list 2 > block.2.out 2>&1 &
     wait

}


# cyclic
# block


my_srun_no_host() {
    # $1 is hosfile
    # $2 is task/gpu count
    # export SLURM_HOSTFILE="$1"
    srun --ntasks=$1 --gpus-per-task=1 --cpus-per-task=4 --ntasks-per-core=1 script.sh
}

# Writing host lists in cyclicly
normal_no_host() {    
     my_srun_no_host 4 > nohost.normal.1.out 2>&1 &
     my_srun_no_host 4 > nohost.normal.2.out 2>&1 &
     wait
}



# Writinng host files in block
block_no_host() {
     my_srun_no_host 6 > nohost.block.1.out 2>&1 &
     my_srun_no_host 2 > nohost.block.2.out 2>&1 &
     wait

}

normal_no_host
block_no_host
