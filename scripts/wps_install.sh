#!/bin/sh
#WPS
cd /shared
mkdir WPS
cd WPS
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/WPSV4.0.TAR.gz
gunzip WPSV4.0.TAR.gz
tar -xf WPSV4.0.TAR
cd WPS
./clean

cat >> ./bashrc << EOF
export JASPERLIB=/usr/lib64/
export JASPERINC=/usr/include/
EOF

source ./bashrc
./configure
