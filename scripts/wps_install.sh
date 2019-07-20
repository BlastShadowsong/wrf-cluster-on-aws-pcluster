#!/bin/sh
#WPS
cd /shared
mkdir WPS
cd WPS
wget http://www2.mmm.ucar.edu/wrf/src/WPSV4.0.TAR.gz
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