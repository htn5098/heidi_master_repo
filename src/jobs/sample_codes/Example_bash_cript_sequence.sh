#!/bin/bash

## labels and outputs
#SBATCH --job-name=project-htnb4d-hai-nguyen


echo "### Starting at: $(date) ###"

# load modules then list loaded modules
#module load netcdf/netcdf-4.6.1-openmpi-3.1.3-hdf5-fortran
#export HDF5_USE_FILE_LOCKING=FALSE
module load R/R-3.2.3
module load python/python-3.5.2

# Running script
## Make folders
mkdir Panels
mkdir Results

## Data Processing
srun python batch_iteration_SPEC1.py
dpfiles=tm-i*.sh
for i in $dpfiles
do
  sbatch --job-name=project-htnb4d-hai-nguyen $i
done

## Model building
echo "#!/bin/bash" > tm-modbuild.sh
echo "#SBATCH --job-name=project-htnb4d-hai-nguyen" >> tm-modbuild.sh
echo "module load R/R-3.2.3" >> tm-modbuild.sh
echo "Rscript Model_building.R GFDL HadGEM2 NorESM1" >> tm-modbuild.sh
sbatch --dependency=singleton --job-name=project-htnb4d-hai-nguyen tm-modbuild.sh

## Analysis
srun python batch_iteration_Analysis.py
srun python batch_iteration_Analysis.py
anfiles=tm-a*.sh
for i in $anfiles
do
  sbatch --dependency=singleton --job-name=project-htnb4d-hai-nguyen $i
done

## Deleting unwanted files
echo "#!/bin/bash" > tm-deleting.sh
echo "#SBATCH --job-name=project-htnb4d-hai-nguyen" >> tm-deleting.sh
echo "rm tm-*" >> tm-deleting.sh
echo "rm -rf Panels" >> tm-deleting.sh
echo "rm slurm*" >> tm-deleting.sh
sbatch --dependency=singleton --job-name=project-htnb4d-hai-nguyen tm-deleting.sh

echo "### Ended at: $(date) ###"