#!/bin/bash -l
#SBATCH -p sgpu_devel --time=01:00:00 --gpus=1

unset SLURM_EXPORT_ENV

module load NVHPC
nvidia-smi
echo Hello World!
hostname

nvcc -O3  --use_fast_math -arch=sm_80 -lcuda -o jacobi-2d jacobi-2d.cu

SZ=$((5*1024+32))

./jacobi-2d $SZ $SZ 32 32 


