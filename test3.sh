# notes.
program="p3"
version="e1"
julia_version=051
addprocs="-p 5"
mainprog="main3.jl"
exectype="pmapbatch"
T=50
distCall="true"

##### Set -b y option to allow command to be a binary file instead of a script.

qsub -b y -N SINGLE -pe smp 5 -cwd -j y \
-o ../03_Log/${program}${version}.o -e ../03_Log/p3e1.e /apps/julia-0.5.1/bin/julia -L startup_file.jl -p 5 main3.jl p3e1 chunk 2 true 
