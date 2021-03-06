#!/usr/bin/python3

import os 
os.chdir(r'/storage/work/h/htn5098/DataAnalysis/src/jobs')
import subprocess 
import sys
import pandas as pd

inputs=sys.argv

inputs.pop(0) # removing the name of the file at the beginning
#room=inputs.pop() # folder for putting files 
action=inputs.pop() # what to do with the download file
rowItems=[int(x) for x in inputs] # turn the list of row names into numbers

link_file = pd.read_csv('../../data/external/Drive_link_UWclim.txt') # reading files containing the links to google drive

for i in rowItems:
  l=link_file.iloc[i] # reading rows in the file with links to google drive
  gcm=l['Data']
  link=l['Link']
  period=l['Period']
  print(gcm,'-',link,'-',period)
  f=open("batch_download_UW_%s_%s.pbs"% (gcm,period),'w')
  f.write("""#!/bin/bash
#-------------------------------------------------------------------------------
# PBS CONFIG
#-------------------------------------------------------------------------------
## Resources
#PBS -N out_%s
#PBS -l nodes=1:ppn=10 # one node and 10 processors
#PBS -l pmem=4gb # memory per processor, total memory = ppn*pmem 
#PBS -l walltime=01:00:00 # max time running
#PBS -A open # accessing the open resources
#PBS -j oe # output and error in one file
#
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

# Go to the directory
cd  /storage/home/htn5098/work/DataAnalysis 
echo "Job started on `hostname` at `date`"
# Run the job
Rscript ./src/Rcodes/RET_downloading_raw.R %s %s %s 
echo "Job ended at `date`"
"""%(gcm,link,period,action)) # 
  f.close() 
  os.system("qsub batch_download_UW_%s_%s.pbs" % (gcm,period))

