#!/bin/bash -l
#SBATCH -N 1 -p intelsr_devel --exclusive --time=00:10:00 --constraint=perfctr
#SBATCH --reservation=hager_workshop_intelsr
#SBATCH --export=NONE

unset SLURM_EXPORT_ENV

module load intel GCC
echo Hello World!
hostname

# choose between C and Fortran
icx -Ofast -xHost -qopt-zmm-usage=high -o ./dmvm.exe C/dmvm.c
#ifx -Ofast -xHost -qopt-zmm-usage=high -o ./dmvm.exe F90/dmvm.f90

# comment out for second part of exercise
srun --cpu-bind=none --cpu-freq=2000000-2000000:performance ./bench.pl ./dmvm.exe 10000

# remove for second part of exercise
exit

# choose between C and Fortran
#icx -DLIKWID_PERFMON -Ofast -xHost -qopt-zmm-usage=high -o ./dmvm.exe C/dmvm-marker.c -llikwid
#ifx -Ofast -xHost -qopt-zmm-usage=high -o ./dmvm.exe F90/dmvm-marker.f90 -llikwid
gcc -DLIKWID_PERFMON -mcmodel=large -Ofast -march=icelake-server -mprefer-vector-width=512 -o ./dmvm.exe C/dmvm-marker.c -llikwid
#gfortran -I/usr/include -Ofast -mcmodel=large -march=icelake-server -mprefer-vector-width=512 -o ./dmvm.exe F90/dmvm-marker.f90 -llikwid

srun --cpu-bind=none --cpu-freq=2000000-2000000:performance ./bench-perf.pl ./dmvm.exe 10000 L2
srun --cpu-bind=none --cpu-freq=2000000-2000000:performance ./bench-perf.pl ./dmvm.exe 10000 L3
srun --cpu-bind=none --cpu-freq=2000000-2000000:performance ./bench-perf.pl ./dmvm.exe 10000 MEM

