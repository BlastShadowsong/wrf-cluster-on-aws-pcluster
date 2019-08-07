#!/bin/sh
#WRF
source ~/.bashrc
cd /shared
mkdir WRF
cd WRF
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/WRF-4.1.2.tar.gz
tar xvf WRF-4.1.2.tar.gz
cd WRFV3
./configure
