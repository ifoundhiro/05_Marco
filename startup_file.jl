##########################################################################
##### Author: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 07/30/2017: Modified.
##### 07/28/2017: Previously modified.
##### 07/28/2017: Created.
##### Description: 
##### 	- Program to set values at startup.
##### Modifications:
#####		07/28/2017:
#####			- Duplicated from startup_file-0.5.jl in 
#####				/home/rcehxm10/Hiro/02_Project/01_Support/01_Program.
#####			- Removed "using override.addprocs."
#####			- Changed shared package repository location.
#####		07/30/2017:
#####			- Changed ENV["JULIA_PKGDIR"] location from
#####				"/home/rcehxm10/Hiro/01_Admin/01_Julia/" to 
#####				"/home/rcehxm10/Hiro/02_Project/05_Marco/01_Program/lib/".
##########################################################################
##### For testing: Add current working dirrectory to LOAD_PATH.
push!(LOAD_PATH,".")
##### Set environmental variable to point to shared package repository.
ENV["JULIA_PKGDIR"]="/home/rcehxm10/Hiro/02_Project/05_Marco/01_Program/lib/";

