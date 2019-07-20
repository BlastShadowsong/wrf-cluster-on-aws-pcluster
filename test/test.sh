#!/bin/sh
#test
source ~/.bashrc
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar \
&& tar -xf Fortran_C_tests.tar \
&& gfortran TEST_1_fortran_only_fixed.f \
&& ./a.out

gfortran TEST_2_fortran_only_free.f90 \
&& ./a.out

gcc TEST_3_c_only.c \
&& ./a.out

gcc -c -m64 TEST_4_fortran+c_c.c \
&& gfortran -c -m64 TEST_4_fortran+c_f.f90 \
&& gfortran -m64 TEST_4_fortran+c_f.o TEST_4_fortran+c_c.o \
&& ./a.out

wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar \
&& tar -xf Fortran_C_NETCDF_MPI_tests.tar

gfortran -c 01_fortran+c+netcdf_f.f \
&& gcc -c 01_fortran+c+netcdf_c.c \
&& gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o \
     -L${NETCDF}/lib -lnetcdff -lnetcdf \
&& ./a.out

mpif90 -c 02_fortran+c+netcdf+mpi_f.f \
&& mpicc -c 02_fortran+c+netcdf+mpi_c.c \
&& mpif90 02_fortran+c+netcdf+mpi_f.o \
	 02_fortran+c+netcdf+mpi_c.o \
     -L${NETCDF}/lib -lnetcdff -lnetcdf \
&& mpirun ./a.out