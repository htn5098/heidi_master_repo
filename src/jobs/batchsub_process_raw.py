#!/usr/bin/python3

import os 
import subprocess 

var = ['tasmax','tasmin','rh_max','rh_min','shortwave','wind_speed']

for y in var:
  if y == 'wind_speed':
    file = "./data/raw/wind_SERC_8th.1979_2016.nc"
  else:
    file = "./data/raw/force_SERC_8th.1979_2016.nc"
  print(y)
  print(file)
  print('\n')   
  f=open("batch_dataprocess-UW-hist-%s.pbs" % y,'w')
  f.write("""#!/bin/bash
#-------------------------------------------------------------------------------
# PBS CONFIG
#-------------------------------------------------------------------------------
## Resources
#PBS -N raw_%s #job name
#PBS -l nodes=1:ppn=10 # one node and 10 processors
#PBS -l pmem=4gb # memory per processor, total memory = ppn*pmem 
#PBS -l walltime=01:00:00 # max time running
#PBS -A open # accessing the open resources
#PBS -j oe # output and error in one file

## Notifications
#PBS -M htn5098@psu.edu # email address for notifications
#PBS -m a # end email when job is aborted
#-------------------------------------------------------------------------------

## Load modules then list loaded modules
module purge
module load r/3.4
module load gcc
module use /gpfs/group/dml129/default/sw/modules
module load netcdf/4.7.1-gcc7.3.1

## Running script     
cd  /gpfs/scratch/htn5098/DataAnalysis/testing/testing_RET_calculation/ # going to the working directory
echo $PBS_JOBID
echo "### Starting at: $(date) ###"
Rscript ./src/Rcodes/RET_processing_rawdata.R %s %s historical 
echo "### Ended at: $(date) ###"
    """%(y,file,y)) # 
  f.close() 
  os.system("qsub batch_dataprocess-UW-hist-%s.pbs" % (y))



