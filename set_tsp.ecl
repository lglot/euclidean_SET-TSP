% Libraries %
:-lib(ic).
:-lib(ic_global).
:-lib(ic_global_gac).
:-lib(listut).
:-lib(branch_and_bound).
:-lib(ic_kernel).
:-lib(lists).

% Instance %
%:-include('instances-clustered/portcgen14/portcgen14_10.d.pl').

:-use_module(set_circuit).
:-[chain].
:-[plot].
:-[util].
:-[nocrossing_clockwise_with_choice].
%:-[distance].

%% BOOLEAN USED TO CHOICE CONSTRAINTS TO APPLY:
%% Ch1 -> clockwise (Clockwise constraint: propagation of predecessors before instantiation) 
%% Ch2 -> CrossAbsence (Ch2=true does not admit crossing)
%% Ch3 -> Sort (Sorted visit as convex hull)

set_tsp:-
	Ch1=1,
	Ch2=1,
	Ch3=0,
	set_tsp(_,_,_,_,Ch1,Ch2,Ch3).

set_tsp(OutputFile):-
	Ch1=1,
	Ch2=1,
	Ch3=0,
	set_tsp(NCluster,Hull,InsideHull,Tsp,Ch1,Ch2,Ch3),
	plot_tsp(NCluster,Hull,InsideHull,Tsp,OutputFile).


set_tsp(Ch1,Ch2,Ch3):-
	cputime(T1),
	set_tsp(_,_,_,_,Ch1,Ch2,Ch3),
	cputime(T2),
	Time is T2-T1,
	writeln(time:Time).

set_tsp(Ch1,Ch2,Ch3,OutputFile):-
	set_tsp(NCluster,Hull,InsideHull,Tsp,Ch1,Ch2,Ch3),
	plot_tsp(NCluster,Hull,InsideHull,Tsp,OutputFile).

set_tsp(NCluster,Hull,InsideHull,Tsp,Ch1,Ch2,Ch3):-
	%% Nodes cardinality
	%distance,
	dimension(N),
	findall(p(X,Y),point(_,X,Y),PCoordinates),

	%% Get Cluster Id on Convex Hull, the list HullCLusterId contains the id
	%% of cluster on convex hull sorted as they appare in convex hull.  
	hull(PCoordinates,Hull),
	(foreach(p(X,Y),Hull), foreach(ClusterId,HullClusterId1), foreach(Id,HullId) do
        once(point(Id,X,Y)),
        once(cluster(ClusterId,Id))
    ),
    remove_duplicates(HullClusterId1,HullClusterId2),
    head(HullClusterId2,Head),
    append(HullClusterId2,[Head],HullClusterId),
	writeln(HullClusterId),

	%% Counts Clusters and saves the value in NCluster variable 
	findall(Clust,cluster(Clust,_),CL),
	sort(CL,CLnodup),
	length(CLnodup,NCluster),

	%% find the "interior" convex hull
	%% ConcaveCluster is the list that contains the id of cluster with nodes inside the interior convex hull
	hull_interna(HullId,InsideHull,ConcaveCluster,NCluster),
	writeln(concaveCluster:ConcaveCluster),
	

	%% Definition of successor variables and their domain:
	%% 1. SuccL is list of tuple arc(Node,Successor): 
	%% 		- Node is ground, Successor is variable
	%% 2. OnlySuccL is a list of only Successor Variables
	length(SuccL,N),
	construct_domain(SuccL),
	(foreach(arc(_,Succ),SuccL), foreach(Succ,OnlySuccL) do true),
	
	
	%% BoolSuccLClustered is a list of list of boolean, each sublist correspond to a cluster
	%% and each boolean variable correspond to a node;
	%% a true variable admits the presence of the node in the set-tsp
	length(BoolSuccLClustered,NCluster),

	

	%% Contraints:
	%% 1. Successors must all be different (alldifferent)
	%% 2. Exactly one node per cluster must be visited, the others not (onenode_per_cluster)
	%% 3. The cycle must be as long as the number of clusters (set_circuit)
	%% NB: The 2. and 3. contraints imply that there is exactly one cycle
	ic_global:alldifferent(OnlySuccL),
	onenode_per_cluster(BoolSuccLClustered,OnlySuccL),
	set_circuit(OnlySuccL,NCluster),

	%Predecessor list
	length(PredL,N),
	PredL #:: 1..N,
	ic_global_gac:inverse(OnlySuccL,PredL),

	%% Optimization: this predicate apply 3 contraints based on the values of the three choice variables (boolean)
	%% Ch1 -> Clockwise constraint
	%% Ch2 -> CrossAbsence (Ch3=true does not admit crossing)
	%% Ch3 -> Sort (Sorted visit of cluster as they appear in convex hull)
	Senso=">", %(">" = Clockwise ; "<" CounterClockwise)
	nocrossing_and_clockwise(BoolSuccLClustered,OnlySuccL,HullClusterId,ConcaveCluster,PredL,Senso,Ch1,Ch2,Ch3),
	
	
	%%Objective function
	cost_tsp(SuccL,Cost),

	%labeling(OnlySuccL),
	minimize(search(OnlySuccL,0,most_constrained,indomain,complete,[backtrack(Back)]),Cost),

	write_list("Succ",OnlySuccL),
	write_list("Pred",PredL),
	get_tsp(NCluster,SuccL,Tsp),
	writeln("tsp":Tsp),
	writeln(numero_backtracking:Back).

% Construct the domain of Successor Variables with the node itself and the nodes of other clusters 
construct_domain(SuccL):-construct_domain(1,SuccL).
construct_domain(_,[]):-!.
construct_domain(Node,[arc(Node,S)|SuccL]):-
	cluster(Cluster,Node),
	findall(NodeDom,(cluster(Cluster2,NodeDom),Cluster2\=Cluster),NodesDom),
	append(NodesDom,[Node],NodesDomain),
	ic:(S::NodesDomain),
	NodeNext is Node+1,
	construct_domain(NodeNext,SuccL).


% Constraints Bool Variables with the presence of node in tsp with reified contraints
% and constraints sum of each bool in the list of a cluster to 1
onenode_per_cluster(BSC,SuccL):-
	onenode_per_cluster(BSC,SuccL,1).
onenode_per_cluster([],_,_).
onenode_per_cluster([BSC|L],SuccL,I):-
	findall(c(N,_),cluster(I,N),BSC),
	(foreach(c(N,B),BSC), foreach(B,BListTemp), param(SuccL) do
		nth1(N,SuccL,Succ),
		$\=(N,Succ,B)
	),
	ic_global:sumlist(BListTemp,1),
	In is I+1,
	onenode_per_cluster(L,SuccL,In).

% Finds the interior convex hull
hull_interna(HullId,InsideHull,ConcaveCluster,NCluster):-
	findall(p(ID,X,Y),point(ID,X,Y),Points),
	hull_interna2(HullId,Points,InsideHull,ConcaveCluster,NCluster).

hull_interna2(HullId,Points,InsideHull,ConcaveCluster,NCluster):-
	(param(HullId),param(Points),for(Clust,1,NCluster), foreach(Diff,DiffList) do
		findall(Id,(cluster(Clust,Id),once(member(Id,HullId))),L1),
		length(L1,N1),
		findall(Id,(cluster(Clust,Id),once(member(p(Id,_,_),Points))),L2),
		length(L2,N2),
		Diff is N2 - N1
	),
	(param(HullId),param(DiffList),foreach(p(ID,X,Y),Points), fromto(PointsNoHull,Out,In,[]) do
			cluster(C,ID),
			nth1(C,DiffList,Diff),
			(once(nonmember(ID,HullId));Diff=<0) -> Out=[p(ID,X,Y)|In] ; Out=In
	),
	(foreach(p(_,X,Y),PointsNoHull), foreach(p(X,Y),PNH) do true),
	hull(PNH,Hull2),
	(foreach(p(X,Y),Hull2), foreach(Id,HullId2) do
        once(point(Id,X,Y))
    ),
    (samelist(HullId,HullId2) -> 
    	findall(Clust,(nth1(Clust,DiffList,Diff),Diff>0),ConcaveCluster),
    	InsideHull = Hull2
    ;	hull_interna2(HullId2,PointsNoHull,InsideHull,ConcaveCluster,NCluster)
    ).


cost_tsp(SuccL,CostTot):-
	findall(c(F,T,C),cost(F,T,C),CostList),
	length(CostList,DIM),
	writeln(DIM),
	(foreach(c(F,T,C),CostList), 
		foreach(F,FromL),
		foreach(T,ToL),
		foreach(C,CostL)
		do true
	),
	cost_tsp_loop(SuccL,FromL,ToL,CostL,SuccCost),
	ic_global:sumlist(SuccCost,CostTot).


cost_tsp_loop([],_,_,_,[]):-!.
cost_tsp_loop([arc(Node,S)|SuccL],FromL,ToL,CostL,[SC|SuccCost]):-
	append(FromL,[Node],FromL1),
	append(ToL,[Node],ToL1),
	append(CostL,[0],CostL1),
	element(I,FromL1,Node),
	element(I,ToL1,S),
	element(I,CostL1,SC),
	cost_tsp_loop(SuccL,FromL,ToL,CostL,SuccCost).

