.all: | proc_rawdata RET_cal

install_package:
	@module purge
	@module load r
	@R --file=../Rcodes/testing_install.R

proc_rawdata: 
	@module load python
	@python batchsub_process_raw.py
	@echo "Processing is in progress"

RET_cal:  
	@qsub 

clean_output:
	rm *.o*

clean_batch:
	rm batch*.pbs

clean_all: clean_output clean_batch
