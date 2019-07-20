#!/bin/sh
#WRF
source ~/.bashrc
cd /shared
mkdir WRF
cd WRF
wget http://www2.mmm.ucar.edu/wrf/src/WRFV3.8.1.TAR.gz
tar xvf WRFV3.8.1.TAR.gz
cd WRFV3
./configure