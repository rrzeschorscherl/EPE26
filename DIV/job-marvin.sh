#!/bin/bash -l
#SBATCH -N 1 -p intelsr_devel --exclusive --time=00:05:00 --constraint=perfctr

unset SLURM_EXPORT_ENV

module load intel likwid
echo Hello World!

# choose between C and Fortran
ifx -Ofast -xHost -qopt-zmm-usage=high -o div.exe  div.f90
icx -Ofast -xHost -qopt-zmm-usage=high -o div.exe  div.c

srun --cpu-bind=none --cpu-freq=2000000-2000000:performance ./div.exe


