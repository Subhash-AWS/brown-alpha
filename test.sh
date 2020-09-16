#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=compute

env
date >> /fsx/output-${SLURM_JOB_ID}.txt
sleep 60
