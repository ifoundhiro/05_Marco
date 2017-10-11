##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                                            
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 08/09/2017: Modified.
##### 08/08/2017: Previously modified.
##### 08/08/2017: Created.
##### Description: 
##### 	- Module to conduct diagnostic tests.
#####		- Refer to the_problem.jl in 
#####			https://github.com/rsarfati/DSGE-Private.jl/tree/pf/src/estimate
##### Modifications:
#####		08/08/2017:
#####			- Duplicated from diagnostics2.jl.
#####			- Begin coding SharedArray solution.
#####		08/09/2017:
#####			- Continue development.
##########################################################################
##### Define module name.
module diagnostics3
##### Load necessary modules.
using HDF5, JLD, DSGE;
using QuantEcon:solve_discrete_lyapunov;
##### Define objects to be exported.
export the_problem

########################################################################
##### EXTERNAL DEFINITIONS
########################################################################

########################################################################
##### Description: Type definition for mutation problem.
########################################################################
type the_problem
	######################################################################
	##### Declare member variables and functions..
	######################################################################
	##### Declare member variables.
	m::DSGE.SmetsWouters{Float64}
	data0::Tuple
	data::Array{Float64,2}
	N_MH::Int64
	c::Float64
	n_particles::Int64
	sysdatapath::String
	system::DSGE.System{Float64}
	RRR::Array{Float64,2}
	TTT::Array{Float64,2}
	S2::Array{Float64,2}
	sqrtS2::Array{Float64,2}
	s0::Array{Float64,1}
	P0::Array{Float64,2}
	n_errors::Int64
	n_states::Int64
	s_lag_tempered_rand_mat::Array{Float64,2}
	ε::Array{Float64,2}
	s_lag_tempered::Array{Float64,2}
	yt::Array{Float64,1}
	nonmissing::Array{Bool,1}
	deterministic::Bool
	μ::Array{Float64,2}
	cov_s::Array{Float64,2}
	s_t_nontempered::Array{Float64,2}
	distCall::Bool
	T::Int64
	batchsize::Int64
	exectype::String
	acpt_vec::Array{Float64,1}
	ε_shared::SharedArray{Float64,2}
	s_t_nontempered_shared::SharedArray{Float64,2}
	acpt_vec_shared::SharedArray{Float64,1}
	seed::Int64
	##### Declare member functions.
	mutation_wrapper::Function
	execute_mutation::Function
	myrange::Function
	mutation_chunk!::Function
	mutation_shared_chunk!::Function
	mutation_shared!::Function
	inputs4chunking::Function
	######################################################################
	##### Define main function.
	######################################################################
	function the_problem()
		##### Create a new instance.
		this=new();
		##### Display prompt.
		println("\n**************************")
		println("***** Initiate Setup *****")
		println("**************************\n")
		##### Create new instance of model.
		this.m=SmetsWouters("ss1",testing=true);
		##### Get data.
		this.data0=get_data();
		##### Display loaded data information.
		println("\nLoaded data type: ",typeof(this.data0));
		##### Convert data into array format.
		this.data=convert(Array{Float64,2},this.data0[1][:,2:end]);
		##### Transpose data.
		this.data=this.data';
		##### Obtain path to system data.
		this.sysdatapath=Pkg.dir()*"/DSGE/test/reference/system.jld";
		##### Load system data.
		this.system=load(this.sysdatapath,"system");
		##### Set parameters.
		this.N_MH=10;
		this.c=0.1;
		this.n_particles=4000;		
		this.RRR=this.system.transition.RRR;
		this.TTT=this.system.transition.TTT;
		this.S2=this.system.measurement.QQ;
		this.sqrtS2=this.RRR*get_chol(this.S2)';
		this.s0=zeros(size(this.TTT)[1]);
		this.P0=nearestSPD(solve_discrete_lyapunov(
		this.TTT,this.RRR*this.S2*this.RRR'));
		this.n_errors=size(this.S2,1);
		this.n_states=size(this.system.measurement.ZZ,2);
		this.s_lag_tempered_rand_mat=randn(this.n_states,this.n_particles);
		this.ε=randn(this.n_errors,this.n_particles);	
		this.s_lag_tempered=repmat(this.s0,1,this.n_particles)+ 
		get_chol(this.P0)'*this.s_lag_tempered_rand_mat;
		this.yt=this.data[:,25];
		this.nonmissing=!isnan(this.yt);
		this.deterministic=false;
		this.μ=mean(this.ε,2);
		this.cov_s=(1/this.n_particles)*(this.ε-repmat(
		this.μ,1,this.n_particles))*(this.ε-repmat(
		this.μ,1,this.n_particles))'
		if !isposdef(this.cov_s)
			this.cov_s=diagm(diag(this.cov_s));
		end	
		this.s_t_nontempered=this.TTT*this.s_lag_tempered+this.sqrtS2*this.ε;		
		this.acpt_vec=zeros(this.n_particles);		
		##### Set default execution values.
		this.T=50;
		this.distCall=true;
		this.exectype="serial";
		##### Set pmap batch size.
		this.batchsize=ceil(this.n_particles/nworkers());
		####################################################################
		##### Define wrapper for mutation problem.
		####################################################################
		function mutation_wrapper(i::Int64)
			##### Define mutation problem.
			mutation_problem(
				this.c,
				this.N_MH,
				this.deterministic,
				this.system,
				this.yt,
				this.s_lag_tempered[:,i],
				this.ε[:,i],
				this.cov_s,
				this.nonmissing,
				this.distCall
			);
		end
		####################################################################
		##### Define function to return indexes assigned to worker.
		####################################################################
		function myrange(ε::SharedArray)
			idx=indexpids(ε);
			if idx == 0 # This worker is not assigned a piece
				return 1:0,1:0;
			end
			nchunks=length(procs(ε));
			splits=[round(Int,s) for s in linspace(0,size(ε,2),nchunks+1)];
			splits[idx]+1:splits[idx+1];
		end
		####################################################################
		##### Define function to execute mutation in chunks.
		####################################################################
		function mutation_chunk!(s_t_nontempered,ε,acpt_vec,inputs,range)
			#@show (range)  # display so we can see what's happening
			for i in range
				s_t_nontempered[:,i],ε[:,i],acpt_vec[i]=
				mutation_problem(
					inputs["c"],
					inputs["N_MH"],
					inputs["deterministic"],
					inputs["system"],
					inputs["yt"],
					inputs["s_lag_tempered"][:,i],
					inputs["ε_shared"][:,i],
					inputs["cov_s"],
					inputs["nonmissing"],
					inputs["distCall"]
				);
			end
			s_t_nontempered,ε,acpt_vec;
		end
		####################################################################
		##### Define convenience wrapper for a SharedArray implementation.
		####################################################################		
		mutation_shared_chunk!(s_t_nontempered,ε,acpt_vec,inputs)=
    mutation_chunk!(s_t_nontempered,ε,acpt_vec,inputs,myrange(ε))
		####################################################################
		##### Define function to delegate work in chunks.
		####################################################################
		function mutation_shared!(s_t_nontempered,ε,acpt_vec,inputs)
			@sync begin
				for p in procs(ε)
						@async remotecall_wait(
						mutation_shared_chunk!,p,s_t_nontempered,ε,acpt_vec,inputs)
					end
				end
			s_t_nontempered,ε,acpt_vec;
		end;		
		####################################################################
		##### Define function to containerize input parameters.
		####################################################################
		function inputs4chunking()
			dict=Dict();
			dict["c"]=this.c;
			dict["N_MH"]=this.N_MH;
			dict["deterministic"]=this.deterministic;
			dict["system"]=this.system;
			dict["yt"]=this.yt;
			dict["s_lag_tempered"]=this.s_lag_tempered;
			dict["ε_shared"]=this.ε_shared;		
			dict["cov_s"]=this.cov_s;
			dict["nonmissing"]=this.nonmissing;
			dict["distCall"]=this.distCall;
			dict;
		end
		####################################################################
		##### Define function to display summary statistics.
		####################################################################
		function show_sum_stats(var,varname::String)
			print("***** ",varname);
			print(" min: ",round(minimum(var),2));
			print(" max: ",round(maximum(var),2));
			print(" mean: ",round(mean(var),2));
			println(" sum: ",round(sum(var),2));
		end	
		####################################################################
		##### Define function to execute mutations using pmap batch.
		####################################################################
		this.execute_mutation=function()
			##### Display prompt.	
			println("\n****************************")
			println("***** Execute Mutation *****")
			println("****************************\n")
			println("***** Test parameters")
			println("*****   Julia version: ",VERSION)
			println("*****   Exec type: ",this.exectype)
			println("*****   # of workers: ",nworkers())
			println("*****   # of time steps: ",this.T)
			println("*****   Use built-in dist fnc: ",this.distCall,"\n")		
			##### Convert output arrays to SharedArrays if chunking specified.
			if this.exectype=="chunk"
				println("***** Convert output arrays to shared");
				this.s_t_nontempered_shared=
				convert(SharedArray,this.s_t_nontempered);
				this.ε_shared=convert(SharedArray,this.ε);
				this.acpt_vec_shared=convert(SharedArray,this.acpt_vec);
			end
			##### Begin timing for entire mutation routine.
			tic();	
			##### Loop over number of specified time steps.
			for t = 1:this.T       
				##### Begin timing for current time step.
				tic();
				##### Run mutation 10 times per time step.
				for i=1:10
					##### Re-initialize vector.
					this.acpt_vec=zeros(this.n_particles);
					this.acpt_vec_shared=zeros(this.n_particles);
					##### Display prompt.
					print("Mutation ");
					##### Begin timing for current iteration.
					tic();
					#############################################################
					##### Run sequentially if specified.
					#############################################################
					if this.exectype=="serial"
						##### Display prompt.
						print("(not parallel) ")
						##### Run sequentially.
						out=[mutation_wrapper(i) for i=1:this.n_particles];					
					#############################################################
					##### Execute parfor if specified.
					#############################################################
					elseif this.exectype=="parfor"
						##### Display prompt.
						print("(in parallel - parfor) ");
						##### Run parallel forloop.
						out = @sync @parallel (hcat) for i=1:this.n_particles
							mutation_wrapper(i);
						end					
					#############################################################
					##### Execute pmap if specified.
					#############################################################
					elseif this.exectype=="pmap"
						##### Display prompt.
						print("(in parallel - pmap) ");
						##### Run default pmap.
						out=pmap(mutation_wrapper,1:this.n_particles);
					#############################################################
					##### Execute pmap with batch if specified.
					#############################################################
					elseif this.exectype=="pmapbatch"
						out=pmap(
							mutation_wrapper,
							1:this.n_particles,
							batch_size=this.batchsize
						);
					#############################################################
					##### Execute chunking if specified.
					#############################################################
					elseif this.exectype=="chunk"	
						##### Execute chunking.
						mutation_shared!(
							this.s_t_nontempered_shared,
							this.ε_shared,
							this.acpt_vec_shared,
							inputs4chunking()
						);
						##### Port results over to local copies.  Having issues
						##### porting into "out"
						this.s_t_nontempered=copy(this.s_t_nontempered_shared);
						this.ε=copy(this.ε_shared);
						this.acpt_vec=copy(this.acpt_vec_shared);
					end
					##### Set prompt counter.
					procnt="Time step: "*string(t)*" Iteration: "*
					string(i)*" Elapsed time: "; 			
					##### Display prompt.
					println(procnt,round(toq(),2)," seconds");
					##### Execute if other than chunking.
					if this.exectype!="chunk"
						##### Disentangle outputs from mutation.
						for j = 1:this.n_particles
							this.s_t_nontempered[:,j] = out[j][1]
							this.ε[:,j] = out[j][2]
							this.acpt_vec[j]=out[j][3]
						end
					end
				end
				##### Display prompt.
				println("***** Completion of period ",t,"/",this.T)
				println("***** Elapsed time: ",round(toq(),2)," seconds")
				show_sum_stats(this.s_t_nontempered,"s_t_nontempered");
				show_sum_stats(this.ε,"ε");
				show_sum_stats(this.acpt_vec,"acpt_vec"); print("\n");
			end   
			##### Display prompt.	
			println("*******************************")
			println("***** Execution Completed *****")
			println("*******************************\n")
			println("***** Test parameters")
			println("*****   Julia version: ",VERSION)
			println("*****   Exec type: ",this.exectype)
			println("*****   # of workers: ",nworkers())
			println("*****   # of time steps: ",this.T)
			println("*****   Use built-in dist fnc: ",this.distCall,"\n")
			println("***** Total elapsed time: ",round(toq(),2)," seconds")
		##### Close function definition.		
		end
		##### Return instance.
		return this
	##### Close function definition.	
	end
##### Close type definition.	
end

########################################################################
##### INTERNAL DEFINITIONS
########################################################################

########################################################################
##### Description: Function to calculate Cholesky of a matrix.
#####	Input parameters:
#####		mat: Matrix.
#####	Output parameters:
#####		Cholesky of input matrix.
########################################################################
function get_chol(
	mat::Array{Float64,2})
	##### Return Cholesky of matrix.
	return Matrix(chol(nearestSPD(mat)));
##### Close function definition.
end

########################################################################
##### Description: Function to return data.
#####	Input parameters:
#####		None.  Assume local load only needed as temporary workaround.
#####	Output parameters:
#####		data: Extracted data object.
########################################################################
function get_data()
	##### Define local data location.
	mydatapath="../02_Data"	
	##### Define dsge folder path.
	filesw="/data/dsge_data_dir/dsgejl/realtime/input_data/data";
	##### Define CSV filename.
	csvname="realtime_spec=smets_wouters_hp=true_vint=110110.csv";
	##### Attempt access to dsge folder.
	try
		##### Load CSV file from dsge folder.	
		data=readcsv("$filesw/"*csvname,header=true);
	##### Execute if error encountered.		
	catch err
		##### Print messages.		
		println("failed to access dsge path: $err");
		println("continuing with local load of csv file");
		##### Load CSV file from local location.
		data=readcsv(mydatapath*"/"*csvname,header=true);
	##### Close try/catch clause.
	end
##### Close function definition.
end

##### Close module definition.
end


