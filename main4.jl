##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/14/2017: Modified.
##### 08/14/2017: Previously modified.
##### 08/14/2017: Created.
##### Description: 
##### 	- Program to run Julia diagnostic tests.
##### Modifications:
##### 		08/14/2017: 
#####			- Duplicated from main4.jl.
#####			- Modify for diagnostics4.jl.
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
println("***** Program name:  ",ARGS[1])
println("***** Datetime:      ",Dates.today()," "
,Dates.format(now(),"HH:MM:SS"))
##########################################################################
##### Extract and display command line arguments.
##########################################################################
##### Extract command line arguments.
i=1; progname=ARGS[i];
i+=1; exectype=ARGS[i];
i+=1; T=parse(Int64,ARGS[i]);
i+=1; distCall=(ARGS[i]=="true"); distCall_str=ARGS[i];
i+=1; parenv=ARGS[i];
##### Display extracted arguments.
println("\n***** Command line arguments")
println("*****   Program name: ",progname)
println("*****   Exec type: ",exectype)
println("*****   # of workers: ",nworkers())
println("*****   # of time steps: ",T)
println("*****   Use built-in dist fnc: ",distCall)
println("*****   Parallel environment: ",parenv,"\n")
##########################################################################
##### Error handle command line arguments.
##########################################################################
##### Check for valid execution type.
if (exectype!="serial" && exectype!="parfor" && exectype!="pmap"
	&& exectype!="pmapbatch" && exectype!="chunk" 
	&& exectype!="chunk2")
	error("invalid command line argument - execution type")
end
##### Check for valid distCall value.
if distCall_str!="true" && distCall_str!="false"
	error("invalid command line argument - distCall")
end
##### Check for mismatch between execution type and number of workers.
if exectype=="serial" && nworkers()>1
	error("command line mismatch between exec type and # of workers")
elseif ((exectype=="parfor" || exectype=="pmap" 
	|| exectype=="pmapbatch" || exectype=="chunk" 
	|| exectype=="chunk2") && nworkers()==1)
	error("command line mismatch between exec type and # of workers")
end
##### Check for compatibility with Julia version if pmap batch.
myver=parse(Int64,join(split(string(VERSION),".")))
if exectype=="pmapbatch" && myver<50
	error("command line mismatch between exec type and julia version")
end
##########################################################################
##### Execute test code.
##########################################################################
##### Load necessary modules.
using diagnostics4;
##### Create new instance of problem.
myprob=diagnostics4.the_problem();
##### Specify test parameters.
myprob.exectype=exectype;
myprob.T=T;
myprob.distCall=distCall;
myprob.parenv=parenv;
##### Execute mutation.
myprob.execute_mutation();
##########################################################################
##### Clean-up workspace.
##########################################################################
##### Remove temporary files.  Note: Shell expression "*" does not expand.
tempfiles=readdir(temppath)
for tempfile in tempfiles
	res=contains(tempfile,progname)
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
println("***** Program name:  ",progname)
println("***** Datetime:      ",Dates.today()," "
,Dates.format(now(),"HH:MM:SS"))
