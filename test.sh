#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4

env
hostname >> /fsx/fsx/shared/mytmp
sleep 60
