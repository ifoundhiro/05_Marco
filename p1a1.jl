##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/03/2017: Modified.
##### 08/02/2017: Previously modified.
##### 07/25/2017: Created.
##### Description: 
##### 	- Program to run Julia diagnostic tests.
#####	- Initial sequential run.
##### Modifications:
#####		07/25/2017: 
#####			- Duplicated from p1c12a1.jl used in Microstructure Noise project.
#####		07/31/2017: 
#####			- Begin importing custom module. 
#####		08/02/2017:
#####			- Begin testing test code.
##### 		08/03/2017: 
#####			- Adjust parameters for testing.
##########################################################################
##### Clear Julia.
workspace()
##### Set relative directory paths.
datapath="../02_Data"
logpath="../03_Log"
graphpath="../04_Graph"
latexpath="../05_Latex"
docpath="../06_Document"
temppath="../07_Temp"
validpath="../08_Validation"
##### Set program name.
program="p1"
version="a1"
##########################################################################
##### Display system information.
##########################################################################
println("\n******************************")
println("***** System Information *****")
println("******************************")
println("***** User:          ",ENV["USER"])
println("***** Julia version: ",VERSION)
println("***** Node:          ",gethostname())
println("***** Directory:     ",pwd())
println("***** Program name:  ",program,version)
println("***** Datetime:      ",Dates.today()," "
,Dates.format(now(),"HH:MM:SS"))
##########################################################################
##### Execute test code.
##########################################################################
##### Specify parameters.
num_procs=1;				##### Number of workers.
exectype="serial";		##### pmap, parfor, serial execution type.
T=2;							##### Number of time steps.
distCall=true;				##### Whether to use built-in distribution function.
##### Add workers if specified.
using ClusterManagers;
if num_procs>1
	addprocs_sge(num_procs,queue="background.q");
##### Set execution type to be sequential if otherwise.
else
	exectype="serial";
end
##### Load necessary modules.
using diagnostics;
##### Execute diagnostic test.
diagnostics.test1(exectype,T,distCall)
##########################################################################
##### Clean-up workspace.
##########################################################################
##### Remove temporary files.  Note: Shell expression "*" does not expand.
tempfiles=readdir(temppath)
for tempfile in tempfiles
	res=contains(tempfile,program*version)
	if res==true
		rm(temppath*"/"*tempfile)
	end
end
##########################################################################
##### Display system information.
##########################################################################
println("\n******************************")
println("***** System Information *****")
println("******************************")
println("***** User:          ",ENV["USER"])
println("***** Julia version: ",VERSION)
println("***** Node:          ",gethostname())
println("***** Directory:     ",pwd())
println("***** Program name:  ",program,version)
println("***** Datetime:      ",Dates.today()," "
,Dates.format(now(),"HH:MM:SS"))
