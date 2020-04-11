#!/usr/bin/python3

import os 
os.chdir(r'/storage/work/h/htn5098/DataAnalysis/src/jobs')
import subprocess 
import sys
import pandas as pd

inputs=sys.argv

gcm=inputs[1]
period=inputs[2] # what to do with the download file

print(gcm)

if period == 'historical':
  var = ['tasmax','tasmin','rh_max','rh_min','shortwave','wind_speed']
else:
  var = ['tasmax','tasmin','rhsmax','rhsmin','OUT_SWDOWN','wind'] 

for y in var:
  if y == 'OUT_SWDOWN':
    file = "energy_bcc-csm1-1_historical.1950_2005.nc"
  else:
    file = "SERC_forcing_bcc-csm1-1_r1i1p1_historical_1950_2005.8th.nc"
  print(y)
  print(file)
  print('\n')   
  f=open("qsub batch_dataprocess-UW-%s-%s-%s.pbs" % (gcm,period,y),'w')
  f.write("""#!/bin/bash
#-------------------------------------------------------------------------------
# PBS CONFIG
#-------------------------------------------------------------------------------
## Resources
#PBS -N %s #job name
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
cd  /storage/work/h/htn5098/DataAnalysis/ # going to the working directory
echo $PBS_JOBID
echo "### Starting at: $(date) ###"
Rscript ./src/Rcodes/RET_processing_rawdata.R %s %s %s %s 
echo "### Ended at: $(date) ###"
    """%(y,file,y,gcm,period)) # 
  f.close() 
#  os.system("qsub batch_dataprocess-UW-%s-%s-%s.pbs" % (gcm,period,y))



