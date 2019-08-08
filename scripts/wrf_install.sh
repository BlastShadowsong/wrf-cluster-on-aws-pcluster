#!/bin/sh
#WRF
source ~/.bashrc
cd /shared
mkdir WRF
cd WRF
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/WRFV4.0.TAR.gz
tar xvf WRFV4.0.TAR.gz
cd WRF
./configure
