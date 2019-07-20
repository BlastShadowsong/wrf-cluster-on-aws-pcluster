#!/bin/sh
#setenv
cat >> ~/.bashrc << EOF
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64
export NETCDF=/shared/netcdf
export PATH=$NETCDF/bin:$PATH
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export PATH=/shared/mpich/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/shared/netcdf/lib
export OMP_NUM_THREADS=9
export KMP_STACKSIZE=128M
export KMP_AFFINITY=granularity=fine,compact,1,0
EOF

source ~/.bashrc
