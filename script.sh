#!/bin/bash

echo ${SLURM_JOB_ID}.${SLURM_STEP_ID}.$SLURM_PROCID START $(date) @ $(hostname): CPUs=$(taskset -c -p $$), GPU-PCI-ID: $(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader,nounits)
sleep 10
echo ${SLURM_JOB_ID}.${SLURM_STEP_ID}.$SLURM_PROCID STOP  $(date)

