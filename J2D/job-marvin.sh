#!/bin/bash -l
#SBATCH -p sgpu_devel --time=01:00:00 --gpus=1
#SBATCH --reservation=hager_workshop_sgpu
#SBATCH --export=NONE

unset SLURM_EXPORT_ENV

module load NVHPC
nvidia-smi
echo Hello World!
hostname

nvcc -O3  --use_fast_math -arch=sm_80 -lcuda -o jacobi-2d jacobi-2d.cu

SIZE=2048
ITER=200
BLOCKSIZE=16

./jacobi-2d $SIZE $SIZE $ITER $BLOCKSIZE $BLOCKSIZE



