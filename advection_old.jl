##########################################################################
##### User: Hirotaka Miura.                                   
##### Position: Research Analytics Associate.                           
##### Organization: Federal Reserve Bank of New York.
##########################################################################   
##### 06/28/2017: Modified.
##### 06/28/2017: Previously modified.
##### 06/28/2017: Created.
##### Description: 
##### 	- Module to implement example running a kernal in parallel.
#####		- See https://docs.julialang.org/en/stable/manual/parallel-computing/#man-shared-arrays-1
##### Modifications:
##########################################################################
##### Define module name.
module advection_old
##### Define objects to be exported.
export advection_serial!, advection_parallel!, advection_shared!
########################################################################

########################################################################
##### INTERNAL FUNCTION DEFINITIONS
########################################################################

##### Function to return (irange, jrange) indexes assigned to worker.
function myrange(q::SharedArray)
	idx = indexpids(q)
	if idx == 0 # This worker is not assigned a piece
		return 1:0, 1:0
	end
	nchunks = length(procs(q))
	splits = [round(Int, s) for s in linspace(0,size(q,2),nchunks+1)]
	1:size(q,1), splits[idx]+1:splits[idx+1]
end;

##### Function for defining kernel.
function advection_chunk!(q, u, irange, jrange, trange)
	@show (irange, jrange, trange)  # display so we can see what's happening
	for t in trange, j in jrange, i in irange
		q[i,j,t+1] = q[i,j,t] + u[i,j,t]
	end
	q
end;

##### Function to define a convenience wrapper for a 
#####	SharedArray implementation
advection_shared_chunk!(q, u) =
advection_chunk!(q, u, myrange(q)..., 1:size(q,3)-1);

########################################################################
##### EXTERNAL FUNCTION DEFINITIONS
########################################################################

##### Function to implement kernel on a single process.
advection_serial!(q, u) = 
advection_chunk!(q, u, 1:size(q,1), 1:size(q,2), 1:size(q,3)-1);

##### Function to implement kernel @parallel.
function advection_parallel!(q, u)
	for t = 1:size(q,3)-1
		@sync @parallel for j = 1:size(q,2)
			for i = 1:size(q,1)
				q[i,j,t+1]= q[i,j,t] + u[i,j,t]
			end
		end
	end
	q
end;

##### Function to implement kernel by delegating data in chunks. .
function advection_shared!(q, u)
	@sync begin
		for p in procs(q)
			@async remotecall_wait(p, advection_shared_chunk!, q, u)
		end
	end
	q
end;

##### End module definition.
end







