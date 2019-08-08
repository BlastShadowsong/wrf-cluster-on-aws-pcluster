### 使用ParallelCluster 安装 WRF(Weather Research and Forecasting) 集群
[AWS ParallelCluster](https://docs.aws.amazon.com/zh_cn/parallelcluster/latest/ug/what-is-aws-parallelcluster.html) 是一个 AWS 支持的开源集群管理工具，它可帮助您在 AWS 云中部署和管理高性能计算 (HPC) 集群。AWS ParallelCluster 在开源 CfnCluster 项目上构建，可让您快速在 AWS 中构建 HPC 计算环境。它自动设置所需的计算资源和共享文件系统。可以将 AWS ParallelCluster 与各种批处理计划程序（例如 AWS Batch、SGE、Torque 和 Slurm）结合使用。

本文将介绍如何使用AWS ParallelCluster 快速构建HPC集群

#### AWS ParallelCluster 安装
* * *
AWS ParallelCluster详细安装过程可以参见[链接](https://aws-parallelcluster.readthedocs.io/en/latest/getting_started.html)
##### Linux/OSX
```
$ pip install aws-parallelcluster --user
```

可以用 pip --version 查看是否已经安装pip，如果没有安装可以使用以下命令安装，参见[链接](https://pip.pypa.io/en/stable/installing）
```
$ curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
$ python get-pip.py --user
```

##### 配置 AWS ParallelCluster
先安装[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
```
$ pip install awscli --user
```
然后进行IAM Credentials设置, IAM Credentials可以从IAM控制台中IAM User中获取，建议给Administrator权限以便调动ParallelCluster需要的所有资源。
```
$ aws configure
AWS Access Key ID [None]: ABCD***********
AWS Secret Access Key [None]: wJalrX********
Default region name [us-east-1]: cn-northwest-1
Default output format [None]: json
```
pcluster初始化
```
$ pcluster configure
```
Configure 向导将带领你一步一步创建你的集群
```
Cluster Template [default]: WRFcluster //集群名
Acceptable Values for AWS Region ID:
    cn-north-1
    cn-northwest-1
AWS Region ID []: cn-northwest-1 //选择部署区域，示例选择的是宁夏区域
VPC Name [public]: prod //命名VPC
Acceptable Values for Key Name:
    handson
    key-cn-northwest-1
Key Name []: key-cn-northwest-1 //选择一个密钥
Acceptable Values for VPC ID:
    vpc-0f1ddb64137540bed
    vpc-503dce39
    vpc-0f48cd7c866f11bf0
VPC ID []: vpc-503dce39 //选择一个VPC
Acceptable Values for Master Subnet ID:
    subnet-41001e39
    subnet-40a46129
    subnet-2486a76e
Master Subnet ID []: subnet-41001e39 //选择子网
```
创建S3桶并上传预安装脚本`pcluster_postinstall.sh`

* 登陆[S3 Console](https://console.amazonaws.cn/s3/home?region=cn-northwest-1)
* 点击创建存储桶，并输入存储桶名
* 点击创建的存储桶
* 点击上传，上传`pcluster_postinstall.sh`

编辑pcluster的配置, 使用vim ~/.parallelcluster/config命令。
pcluster configure时已经设置了VPC、subnet等信息，依然沿用之前的设置；从extra_date到volume_size部分可以直接复制粘贴示例脚本，添加到config文件中间部分。
修改post_install为上一步文件上传的s3位置。
```
[aws]
aws_region_name = cn-northwest-1

[cluster WRFcluster]
vpc_settings = prod
key_name = key-cn-northwest-1
extra_json = { "cluster" : { "cfn_scheduler_slots" : "cores", "ganglia_enabled" : "yes" } }
## 自己的脚本地址
post_install = s3://wrfcluster-demo/pcluster_postinstall.sh
## 自己的S3桶ARN
s3_read_write_resource = arn:aws-cn:s3:::wrfcluster-demo/*
## 计算节点类型
compute_instance_type = c5.9xlarge
## 主节点类型
master_instance_type = m5.xlarge
## 根卷大小
master_root_volume_size = 100
## 计算节点根卷大小，需大于ami需要，选填
compute_root_volume_size = 100
## AutoScailing设置，选填
scaling_settings = WRF-ASG
## 初始队列大小，默认为2，选填
initial_queue_size = 1
## 最大队列容量，默认10，选填
max_queue_size = 2
placement = cluster
placement_group = DYNAMIC
cluster_type = ondemand
base_os = alinux
## 调度工具配置
scheduler = torque
## 数据卷配置
ebs_settings = wrf-ebs

#auto scaling设置
[scaling WRF-ASG]
#节点检测间隔，5分钟无负载则缩减，默认15分钟，选填
scaledown_idletime = 5

[ebs wrf-ebs]  ## Used for the NFS mounted file system
## 数据卷类型
volume_type = gp2
## 数据卷大小(GB)
volume_size = 2000

[vpc prod]
master_subnet_id = subnet-41001e39
vpc_id = vpc-503dce39

[global]
update_check = true
sanity_check = true
cluster_template = WRFcluster

[aliases]
ssh = ssh {CFN_USER}@{MASTER_IP} {ARGS}
```
创建集群
```
$ pcluster create WRFcluster
```
等待集群创建完成。如果集群创建失败，请检查相应Region的EC2限制是否小于设定的集群最大节点数，如果受限于EC2 limit，可以开support case提高limit，或者修改设置降低最大节点数。

#### WRF及相关库的安装
* * *
通过ssh登陆到Master节点
```
$ ssh -i "key-cn-northwest-1.pem" ec2-user@ec2-x-x-x-x.cn-northwest-1.compute.amazonaws.com.cn -o tcpkeepalive=yes -o serveraliveinterval=50
```
更新并安装jasper
```
$ sudo yum upgrade -y \
&& sudo yum install gcc64-gfortran.x86_64 libgfortran.x86_64 jasper jasper-libs.x86_64 jasper-devel.x86_64 libpng-devel.x86_64 -y
```

将这个仓库下载到本地，例如共享卷/shared目录下，然后进入相应目录
```
$ cd /shared
$ git clone https://github.com/BlastShadowsong/wrf-cluster-on-aws-pcluster.git
$ cd wrf-cluster-on-aws-pcluster/
```

依次安装NetCDF 4.1.3, MPICH 3.0.4
* NetCDF
```
$ sh scripts/netcdf_install.sh
```
* MPICH
```
$ sh scripts/mpich_install.sh
```
安装WRF 4.0
```
$ sh scripts/wrf_install.sh
```
出现选项
```
Please select from among the following Linux x86_64 options:

  1. (serial)   2. (smpar)   3. (dmpar)   4. (dm+sm)   PGI (pgf90/gcc)
  5. (serial)   6. (smpar)   7. (dmpar)   8. (dm+sm)   PGI (pgf90/pgcc): SGI MPT
  9. (serial)  10. (smpar)  11. (dmpar)  12. (dm+sm)   PGI (pgf90/gcc): PGI accelerator
 13. (serial)  14. (smpar)  15. (dmpar)  16. (dm+sm)   INTEL (ifort/icc)
                                         17. (dm+sm)   INTEL (ifort/icc): Xeon Phi (MIC architecture)
 18. (serial)  19. (smpar)  20. (dmpar)  21. (dm+sm)   INTEL (ifort/icc): Xeon (SNB with AVX mods)
 22. (serial)  23. (smpar)  24. (dmpar)  25. (dm+sm)   INTEL (ifort/icc): SGI MPT
 26. (serial)  27. (smpar)  28. (dmpar)  29. (dm+sm)   INTEL (ifort/icc): IBM POE
 30. (serial)               31. (dmpar)                PATHSCALE (pathf90/pathcc)
 32. (serial)  33. (smpar)  34. (dmpar)  35. (dm+sm)   GNU (gfortran/gcc)
 36. (serial)  37. (smpar)  38. (dmpar)  39. (dm+sm)   IBM (xlf90_r/cc_r)
 40. (serial)  41. (smpar)  42. (dmpar)  43. (dm+sm)   PGI (ftn/gcc): Cray XC CLE
 44. (serial)  45. (smpar)  46. (dmpar)  47. (dm+sm)   CRAY CCE (ftn/cc): Cray XE and XC
 48. (serial)  49. (smpar)  50. (dmpar)  51. (dm+sm)   INTEL (ftn/icc): Cray XC
 52. (serial)  53. (smpar)  54. (dmpar)  55. (dm+sm)   PGI (pgf90/pgcc)
 56. (serial)  57. (smpar)  58. (dmpar)  59. (dm+sm)   PGI (pgf90/gcc): -f90=pgf90
 60. (serial)  61. (smpar)  62. (dmpar)  63. (dm+sm)   PGI (pgf90/pgcc): -f90=pgf90
 64. (serial)  65. (smpar)  66. (dmpar)  67. (dm+sm)   INTEL (ifort/icc): HSW/BDW
 68. (serial)  69. (smpar)  70. (dmpar)  71. (dm+sm)   INTEL (ifort/icc): KNL MIC
```
选择“34” (dmpar)，然后再选择 “1”
```
Enter selection [1-71] : 34
------------------------------------------------------------------------
Compile for nesting? (1=basic, 2=preset moves, 3=vortex following) [default 1]: 1

```
编译选项
```
em_real (3d real case)
em_quarter_ss (3d ideal case)
em_b_wave (3d ideal case)
em_les (3d ideal case)
em_heldsuarez (3d ideal case)
em_tropical_cyclone (3d ideal case)
em_hill2d_x (2d ideal case)
em_squall2d_x (2d ideal case)
em_squall2d_y (2d ideal case)
em_grav2d_x (2d ideal case)
em_seabreeze2d_x (2d ideal case)
em_scm_xy (1d ideal case)
```
在本次实验中选择em_real模式
```
$ cd /shared/WRF/WRF
$ source ~/.bashrc
$ ./compile em_real 2>&1 | tee compile.log
```
如果安装成功，则可以看到如下信息
```
==========================================================================
build started:   Fri Jul 19 12:16:09 UTC 2019
build completed: Fri Jul 19 12:21:41 UTC 2019

--->                  Executables successfully built                  <---

-rwxrwxr-x 1 ec2-user ec2-user 38094992 Jul 19 12:21 main/ndown.exe
-rwxrwxr-x 1 ec2-user ec2-user 37975624 Jul 19 12:21 main/real.exe
-rwxrwxr-x 1 ec2-user ec2-user 37595344 Jul 19 12:21 main/tc.exe
-rwxrwxr-x 1 ec2-user ec2-user 41805008 Jul 19 12:21 main/wrf.exe

==========================================================================
```
安装WPS 4.0
```
$ sh scripts/wps_install.sh
```
选项列表
```
Please select from among the following supported platforms.

   1.  Linux x86_64, gfortran    (serial)
   2.  Linux x86_64, gfortran    (serial_NO_GRIB2)
   3.  Linux x86_64, gfortran    (dmpar)
   4.  Linux x86_64, gfortran    (dmpar_NO_GRIB2)
   5.  Linux x86_64, PGI compiler   (serial)
   6.  Linux x86_64, PGI compiler   (serial_NO_GRIB2)
   7.  Linux x86_64, PGI compiler   (dmpar)
   8.  Linux x86_64, PGI compiler   (dmpar_NO_GRIB2)
   9.  Linux x86_64, PGI compiler, SGI MPT   (serial)
  10.  Linux x86_64, PGI compiler, SGI MPT   (serial_NO_GRIB2)
  11.  Linux x86_64, PGI compiler, SGI MPT   (dmpar)
  12.  Linux x86_64, PGI compiler, SGI MPT   (dmpar_NO_GRIB2)
  13.  Linux x86_64, IA64 and Opteron    (serial)
  14.  Linux x86_64, IA64 and Opteron    (serial_NO_GRIB2)
  15.  Linux x86_64, IA64 and Opteron    (dmpar)
  16.  Linux x86_64, IA64 and Opteron    (dmpar_NO_GRIB2)
  17.  Linux x86_64, Intel compiler    (serial)
  18.  Linux x86_64, Intel compiler    (serial_NO_GRIB2)
  19.  Linux x86_64, Intel compiler    (dmpar)
  20.  Linux x86_64, Intel compiler    (dmpar_NO_GRIB2)
  21.  Linux x86_64, Intel compiler, SGI MPT    (serial)
  22.  Linux x86_64, Intel compiler, SGI MPT    (serial_NO_GRIB2)
  23.  Linux x86_64, Intel compiler, SGI MPT    (dmpar)
  24.  Linux x86_64, Intel compiler, SGI MPT    (dmpar_NO_GRIB2)
  25.  Linux x86_64, Intel compiler, IBM POE    (serial)
  26.  Linux x86_64, Intel compiler, IBM POE    (serial_NO_GRIB2)
  27.  Linux x86_64, Intel compiler, IBM POE    (dmpar)
  28.  Linux x86_64, Intel compiler, IBM POE    (dmpar_NO_GRIB2)
  29.  Linux x86_64 g95 compiler     (serial)
  30.  Linux x86_64 g95 compiler     (serial_NO_GRIB2)
  31.  Linux x86_64 g95 compiler     (dmpar)
  32.  Linux x86_64 g95 compiler     (dmpar_NO_GRIB2)
  33.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (serial)
  34.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (serial_NO_GRIB2)
  35.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (dmpar)
  36.  Cray XE/XC CLE/Linux x86_64, Cray compiler   (dmpar_NO_GRIB2)
  37.  Cray XC CLE/Linux x86_64, Intel compiler   (serial)
  38.  Cray XC CLE/Linux x86_64, Intel compiler   (serial_NO_GRIB2)
  39.  Cray XC CLE/Linux x86_64, Intel compiler   (dmpar)
  40.  Cray XC CLE/Linux x86_64, Intel compiler   (dmpar_NO_GRIB2)
```
选择“1”完成配置
因为`metgrid.exe`和`geogrid.exe`程序依赖WRF的I/O库，需要配置WRF路径在`configure.wps`中
* 编辑文件
```
$ vim configure.wps
```
* 找到其中指定WRF路径的两行
```
WRF_DIR = ../../WRF/WRF
```
* 修改为
```
WRF_DIR = ../../WRF/WRF
```
编译WPS
```
$ source ~/.bashrc
$ ./compile 2>&1 | tee compile.log
```
如果安装成功则，能看到WPS目录下有如下三个文件
* geogrid.exe -> geogrid/src/geogrid.exe
* ungrib.exe -> ungrib/src/ungrib.exe
* metgrid.exe -> metgrid/src/metgrid.exe

到此，我们完成WRF的全部安装过程，你可以基于已有的数据进行相关的实验了

#### WRF的运行与并行计算
* * *
##### 下载实验数据
1. 下载静态地理数据，在/shared 目录下新建文件夹Build_WRF，下载到其中，可从官方网站获取：http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html
```
$ cd /shared
$ mkdir Build_WRF
$ cd Build_WRF
$ wget http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html
```

然后解压缩静态地理数据，并取消tar文件，2.6G的文件最终会成为29G的文件。文件较大，需要等待一段时间。解压缩后的文件名称为WPS_GEOG
```
$ gunzip geog_high_res_mandatory.tar.gz
$ tar -xf geog_high_res_mandatory.tar
```

然后修改 namelist.wps 文件中的 &geogrid 部分，将静态文件目录提供给geogrid程序。
```
$ cd /shared/WPS/WPS
$ vim namelist.wps
$ geog_data_path =' shared/Build_WRF/WPS_GEOG/'
```

2. 下载实时数据，可从官方网站获取：ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod
在 /shared/Build_WRF 目录下创建一个目录 DATA，将实时数据下载到 DATA 中。
本例中下载2019年8月1日的f000、f006、f012三个数据作为测试数据，您可以根据自己的需求选择其他实时数据用于测试。
```
$ cd /shared/Build_WRF
$ mkdir DATA
$ cd DATA
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20190801/00/gfs.t00z.pgrb2.0p50.f000
$ mv gfs.t00z.pgrb2.0p50.f000 GFS_00h
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20190801/00/gfs.t00z.pgrb2.0p50.f006
$ mv gfs.t00z.pgrb2.0p50.f006 GFS_06h
$ wget ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.20190801/00/gfs.t00z.pgrb2.0p50.f012
$ mv gfs.t00z.pgrb2.0p50.f012 GFS_12h
```

##### 运行WPS
1. 运行geogrid，转到WPS目录中
```
$ cd /shared/WPS/WPS
$ ./geogrid.exe>＆log.geogrid
```
这一步运行成功的标志是创建了 geo_em.* 文件，在本例中为 geo_em.d01.nc 和 geo_em.d02.nc

2. 运行ungrib，首先修改链接到GFS和Vtables的正确位置
```
$ ./link_grib.csh /shared/Build_WRF/DATA/
$ ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable
```

然后修改 namelist.wps 文件的 start_date 和 end_date，与实时数据相契合
```
start_date = '2019-08-01_00:00:00','2019-08-01_00:00:00',
end_date   = '2019-08-01_12:00:00','2019-08-01_12:00:00',
```

然后运行ungrib
```
$ ./ungrib.exe
```
这一步运行成功的标志是创建了 FILE:* 文件，在本例中为 FILE:2019-08-01_00、FILE:2019-08-01_06、FILE:2019-08-01_12

3. 运行metgrid
```
$ ./metgrid.exe>＆log.metgrid
```
这一步运行成功的标志是创建了 met_em* 文件


#### 运行WRF
1. 进入WRF目录，将 met_em.* 文件复制到工作目录
```
$ cd /shared/WRF/WRF/run
$ cp /shared/WPS/WPS/met_em* /shared/WRF/WRF/run/
```

2. 修改 namelist.input 文件中的开始和结束时间，每一行三项设置为相同时间，开始和结束时间与实时数据相契合；修改 num_metgrid_levels 参数为34，与实时数据相契合。

3. 运行real程序
```
$ mpirun -np 1 ./real.exe
```
检查输出文件以确保运行成功，运行成功后会看到每个域的 wrfbdy_d01 和 wrfinput_d0* 文件。如果有错误，根据文件中的提示修改 namelist.input 文件中的参数。
```
$ tail rsl.error.0000
```

4. 运行WRF，可自行修改 np 参数，但要小于实例的物理核数。
```
$ mpirun -np 8 ./wrf.exe
```
运行成功的标志是 rsl.out.0000 文件中有 SUCCESS结尾，并生成 wrfout* 文件。

5. 制作任务脚本
```
$ vim job.sh
```
任务脚本的内容为
```
#!/bin/bash
#PBS -N WRF
#PBS -l nodes=1:ppn=18
#PBS -o wrf.out
#PBS -e wrf.err
echo "Start time: "
date
cd /shared/WRF/WRF/run
/shared/mpich/bin/mpirun /shared/WRF/WRF/run/wrf.exe
echo "End time: "
date
```
其中 PBS -N 为任务名称，-l 控制并行节点数和每个节点的计算核数，-o 和 -e 为结果日志和错误日志的输出位置。这些参数都可以结合实际需求灵活更改。

6. 提交任务到计算节点
```
$ qsub job.sh
```
之后可以用 qnodes 命令查看节点情况，用 qstat 命令查看任务运行情况，通过 rsl.out.0000 查看运行过程。
任务运行完成后，可以在生成的 wrf.out 文件中查看运行起止时间，来计算实际运行时长。


#### 实验环境销毁
* * *
1. 删除上传至S3中的资源
2. 运行以下命令，删除AWS ParallelCluster创建的全部资源
```
$ pcluster delete WRFcluster
```

#### 参考资料
[Run WPS and WRF](http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php#STEP8)
