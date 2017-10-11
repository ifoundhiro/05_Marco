##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/09/2017: Modified.
#####	08/09/2017: Previously modified.
#####	08/09/2017: Created.
#####	Description: 
#####		- Bash script for launching Julia jobs.
#####		- Refer to "main.jl" for command line arguments.
#####		- Julia v0.5.1 chunk. 
#####	Modifications:
##########################################################################

#!/bin/bash
##### Define local variables.
program="p3"
version="e1"
julia_version=051
addprocs="-p 5"
mainprog="main3.jl"
exectype="chunk"
T=50
distCall="true"
##### Set datetime variable.
datetime=`date +%Y%m%d%H%M%S`
##### Execute program.
./jwrap${julia_version} \
${addprocs} \
${mainprog} \
${program}${version} \
${exectype} \
${T} \
${distCall} > \
../03_Log/${program}${version}-${julia_version}_${datetime}.log 2>&1
