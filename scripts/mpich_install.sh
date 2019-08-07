#!/bin/sh
#MPICH

#install
source ~/.bashrc
cd /shared
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/mpich-3.0.4.tar.gz
tar xzvf mpich-3.0.4.tar.gz
cd mpich-3.0.4
./configure --prefix=/shared/mpich
make
make install

#setenv
echo "export PATH=/shared/mpich/bin:$PATH" >> ~/.bashrc
