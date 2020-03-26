#!/bin/bash
#PBS -N o_tstloop
#PBS -l nodes=1:ppn=10
#PBS -l pmem=4gb
#PBS -l walltime=02:00:00
#PBS -A open
#PBS -j oe

# Loading modules
module purge
module load r

echo "Job started on `hostname` at `date`"

# Go to the directory
cd /storage/home/htn5098/work/DataAnalysis/src/Rcodes

# Run the job
R --file=test_loop.R

echo "Job ended at `date`"