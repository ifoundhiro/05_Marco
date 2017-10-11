##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/10/2017: Modified.
#####	08/10/2017: Previously modified.
#####	08/10/2017: Created.
#####	Description: 
#####		- Bash script for launching Julia jobs.
#####		- Refer to "main.jl" for command line arguments.
#####		- Julia v0.5.1 chunk. 
#####		- 15 workers.
#####		- Run on same node.
#####	Modifications:
##########################################################################

#!/bin/bash

##########################################################################
##### Define local variables.
##########################################################################
program="p3"
version="e3"
julia_version="0.5.1"
workers="15"
mainprog="main3.jl"
exectype="chunk"
T=50
distCall="true"
##### Set distributed type.
##### Set to "julia" if executing across nodes.
##### Set to "smp" if executing on one node.
disttype="smp"				
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
qsub -b y -pe ${disttype} ${workers} -cwd \
-o ../03_Log/${program}${version}-${julia_version}_${datetime}.o \
-e ../03_Log/${program}${version}-${julia_version}_${datetime}.e \
/apps/julia-${julia_version}/bin/julia -L startup_file.jl \
-p ${workers} \
${mainprog} \
${program}${version} \
${exectype} \
${T} \
${distCall} 

