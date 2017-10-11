# notes.
program="test"
version="4"
julia_version="0.5.1"
workers="5"
mainprog="main3.jl"
exectype="pmapbatch"
T=2
distCall="true"

##### Set datetime variable.
datetime=`date +%Y%m%d%H%M%S`
##### Specify qsub command.
##### Set "-b y" option to allow command to be a binary file instead of a script.
##### Set "-pe smp #" distributed type and worker #.
##### Set "-cwd" to run from current working director.
##### Set "-o <path>" for logging output.
##### Set "-e <path>" for logging errors.
##### Rest of commands Julia specific.
qsub -b y -pe smp ${workers} -cwd \
-o ../03_Log/${program}${version}-${julia_version}_${datetime}.o \
-e ../03_Log/${program}${version}-${julia_version}_${datetime}.e \
/apps/julia-${julia_version}/bin/julia -L startup_file.jl \
-p ${workers} \
${mainprog} \
${program}${version} \
${exectype} \
${T} \
${distCall} 
