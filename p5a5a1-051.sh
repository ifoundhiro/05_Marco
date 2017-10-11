##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/14/2017: Modified.
#####	08/14/2017: Previously modified.
#####	08/14/2017: Created.
#####	Description: 
#####		- Bash script for launching Julia jobs.
#####		- Main: main4.jl.
#####		- Julia version: 0.5.1.
#####		- Execution type: Chunking. 
#####		- # of workers: 32.
#####		- Parallel environment: Multiple nodes.
#####	Modifications:
#####		- Duplicated from p5a5-051.sh.
#####		- Change parallel environment from "matlab" to "julia."
##########################################################################

#!/bin/bash

##########################################################################
##### Define local variables.
##########################################################################
program="p5"
version="a5a1"
julia_version="0.5.1"
workers="32"
mainprog="main4.jl"
exectype="chunk2"
T=10
distCall="true"
##### Set parallel environment.
##### Set to "julia" if executing across nodes.
##### Set to "smp" if executing on one node.
##### Set to "matlab" if executing across nodes and "julia" errors out.
parenv="julia"				
##### Set datetime variable.
datetime=`date +%Y%m%d%H%M%S`

##########################################################################
##### Specify scheduler command.
##########################################################################
##### Set "-b y" option to allow command to be a binary file instead of a script.
##### Set "-pe smp #" distributed type and worker #.
##### Set "-cwd" to run from current working director.
##### Set "-o <path>" for logging output.
##### Set "-e <path>" for logging errors.
##### Rest of commands Julia specific.
qsub -b y -pe ${parenv} ${workers} -cwd \
-o ../03_Log/${program}${version}-${julia_version}_${datetime}.o \
-e ../03_Log/${program}${version}-${julia_version}_${datetime}.e \
/apps/julia-${julia_version}/bin/julia -L startup_file.jl \
-p ${workers} \
${mainprog} \
${program}${version} \
${exectype} \
${T} \
${distCall} \
${parenv}
