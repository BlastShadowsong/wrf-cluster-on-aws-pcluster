#!/bin/sh
#NetCDF

#setenv
cat >> ~/.bashrc << EOF
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64
EOF

#install
source ~/.bashrc
cd /shared
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/netcdf-4.1.3.tar.gz
tar xvf netcdf-4.1.3.tar.gz
cd netcdf-4.1.3
./configure --prefix=/shared/netcdf --disable-netcdf-4 --disable-dap --disable-shared
make
make check 2>&1 | tee make.check.out
grep passed make.check.out
make install

#setenv
cat >> ~/.bashrc << EOF
export NETCDF=/shared/netcdf
export PATH=$NETCDF/bin:$PATH
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
EOF
