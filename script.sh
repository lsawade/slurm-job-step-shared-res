#!/bin/bash
1;95;0c

echo ${SLURM_JOB_ID}.${SLURM_STEP_ID}.$SLURM_PROCID START $(date) @ $(hostname): $CUDA_VISIBLE_DEVICES
sleep 60
echo ${SLURM_JOB_ID}.${SLURM_STEP_ID}.$SLURM_PROCID STOP  $(date)

