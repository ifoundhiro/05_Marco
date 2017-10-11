##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/07/2017: Modified.
##### 08/07/2017: Previously modified.
##### 08/07/2017: Created.
##### Description: 
##### 	- Program to run example advection routine.
#####		- See https://docs.julialang.org/en/stable/manual/parallel-computing/#man-shared-arrays-1
##### Modifications:
#####	08/07/2017:
#####		- Duplicated from p1b1.jl in 
#####			Z:\RDS\Work\rsf\b1hxm10\02_Project\09_Rebecca\01_Program.
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
version="b1"
##########################################################################
##### Display program information.
##########################################################################
println("\n*******************************")
println("***** Program Information *****")
println("*******************************")
println("***** User:          ",ENV["USER"])
println("***** Julia version: ",VERSION)
println("***** Node:          ",gethostname())
println("***** Directory:     ",pwd())
println("***** Program name:  ",string(program,version))
println("***** Datetime:      ",Dates.today()," ",
Dates.format(now(),"HH:MM:SS"))
##########################################################################
##### Setup.
##########################################################################
##### Display number of workers.
println("\nWorkers: ",workers(),"\n")
##### Put current working directory in path to be searched for modules.
push!(LOAD_PATH, ".")
##### Load modules.
using advection
##### Initialize shared arrays.
q = SharedArray{Float64, 3}(ones(500,500,500));
u = SharedArray{Float64, 3}(ones(500,500,500));
##########################################################################
##### Implement calculationss.
##########################################################################
##### Single process.
exp="@time advection_serial!(q, u);"; println(exp);
eval(parse(exp)); println("\n");
##### Using @parallel.
exp="@time advection_parallel!(q, u);"; println(exp);
eval(parse(exp)); println("\n");
##### Delegating into chunks.
exp="@time advection_shared!(q,u);"; println(exp);
eval(parse(exp)); println("\n");
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
##### Display program information.
##########################################################################
println("\n*******************************")
println("***** Program Information *****")
println("*******************************")
println("***** User:          ",ENV["USER"])
println("***** Julia version: ",VERSION)
println("***** Node:          ",gethostname())
println("***** Directory:     ",pwd())
println("***** Program name:  ",string(program,version))
println("***** Datetime:      ",Dates.today()," ",
Dates.format(now(),"HH:MM:SS"))



