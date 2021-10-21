#!/bin/bash

sleep $((7 * $1))
sleep $SLURM_PROCID
echo SCRIPT: $1 -- JOB: $SLURM_JOB_ID -- STEP: $SLURM_STEP_ID -- PROC: $SLURM_PROCID
sleep 60

