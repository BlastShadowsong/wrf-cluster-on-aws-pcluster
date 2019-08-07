#!/bin/sh
#WPS
cd /shared
mkdir WPS
cd WPS
wget https://wrf-softwares.s3.cn-northwest-1.amazonaws.com.cn/WPS-4.1.tar.gz
gunzip WPS-4.1.tar.gz
tar -xf WPS-4.1.tar
cd WPS
./clean

cat >> ./bashrc << EOF
export JASPERLIB=/usr/lib64/
export JASPERINC=/usr/include/
EOF

source ./bashrc
./configure
