#!/bin/bash
#PBS -N out_tstloop
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
#cd /storage/home/htn5098/work/DataAnalysis/src/Rcodes
cd /storage/home/htn5098/work/DataAnalysis/src/jobs/

# Run the job
## Run R codes
#R --file=test_loop.R

## Run job chain
qsub job1.pbs
qsub job2.pbs -W depend=afterok:out_job1
echo "Job ended at `date`"