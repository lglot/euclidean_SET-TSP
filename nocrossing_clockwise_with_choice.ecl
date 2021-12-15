%% BOOLEAN USED TO CHOICE CONSTRAINTS TO APPLY:
%% Ch1 -> clockwise (Clockwise constraint: propagation of predecessors before instantiation) 
%% Ch2 -> Sort (Sorted visit as convex hull)
%% Ch3 -> CrossAbsence (Ch3=true does not admit crossing)

%% Executions labels:
%% normal -> Ch1=1,Ch2=1,Ch3=1
%% nopredtosucc -> Ch1=0,Ch2=1,Ch3=1
%% nosort -> Ch1=1,Ch2=0,Ch3=1
%% noboth -> Ch1=0,Ch2=0,Ch3=1
%% cross -> Ch1=1,Ch2=1,Ch3=0
%% nopredtosucc_cross -> Ch1=0,Ch2=1,Ch3=0
%% nosort_cross -> Ch1=1,Ch2=0,Ch3=0
%% noboth_cross -> Ch1=0,Ch2=0,Ch3=0

:-[pred_prog].

nocrossing_and_clockwise(BoolSucc,OnlySuccL,HullClusterId,ConcaveCluster,PredL,Direction,Ch1,Ch2,Ch3):-
	(Ch1=1 ->
		pred_to_succ_propagation(1,PredL,OnlySuccL,HullClusterId,ConcaveCluster,Direction)
	; true
	),
	nocrossing_and_clockwise1(1,BoolSucc,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2,Ch3).


nocrossing_and_clockwise1(_,[],_,_,_,_,_,_,_).
nocrossing_and_clockwise1(I,[BSC|BSCl],OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2,Ch3):-
	(param(I),foreach(Succ,OnlySuccL), count(ID,1,_), fromto(SuccClusteredL,Out,In,[]) do
		cluster(I,ID) -> Out=[Succ|In] ; Out=In
	),
	
	(once(member(I,HullClusterId)),nonmember(I,ConcaveCluster),Ch3=1 ->
		excludeNextNodeOnHull(I,SuccClusteredL,HullClusterId,ConcaveCluster,Direction)
	; true
	),

	ic_global:sumlist(SuccClusteredL,Somma),
	(var(Somma) ->
			suspend(nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2),5,Somma->suspend:inst)
		; 	nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2)
	),
	
	Inext is I + 1,
	nocrossing_and_clockwise1(Inext,BSCl,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2,Ch3).


excludeNextNodeOnHull(IdCluster,SuccClusteredL,HullClusterId,ConcaveCluster,Direction):-
	subtract(HullClusterId,ConcaveCluster,ClusterToVisitInOrder),
	head(ClusterToVisitInOrder,Head),
    append(ClusterToVisitInOrder,[Head],ClusterToVisitInOrder2),
	nth1(Pos,ClusterToVisitInOrder2,IdCluster),
	(Direction=">" -> 
		NexTPos is Pos + 1,!
	; 	
		(Pos=1 -> fail; !),
		NexTPos is Pos - 1
	),
	nth1(NexTPos,ClusterToVisitInOrder2,IdNextCluster),
	findall(NodeToRemove,(cluster(C,NodeToRemove),C\=IdNextCluster,C\=IdCluster,once(member(C,ClusterToVisitInOrder2))),NodesToRemoveList),
	(param(NodesToRemoveList),foreach(Succ,SuccClusteredL) do
		(param(Succ),foreach(NDT,NodesToRemoveList) do exclude(Succ,NDT))
	).




nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2):-
	once(member(c(IdNode,1),BSC)),
	nth1(IdNode,OnlySuccL,Succ),
	once(point(IdNode,X0,Y0)),
	once(point(Succ,X1,Y1)),
	once(cluster(Cl1,IdNode)),
	once(cluster(Cl2,Succ)),
	remove_cross_points(IdNode,X0,Y0,X1,Y1,1,OnlySuccL,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2).


remove_cross_points(_,_,_,_,_,_,[],_,_,_,_,_,_,_,_).
remove_cross_points(Id,XA,YA,XB,YB,N,[C|L],OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2):-
	once(point(N,Xc,Yc)),
	SignABc is (Yc-YA)*(XB-XA) - (Xc-XA)*(YB-YA),
	((Ch1=1,cluster(I,Id),once(member(I,HullClusterId)),nonmember(I,ConcaveCluster)) ->
		(check_sign_direction(Direction,SignABc) ->
				exclude(C,Id)
		    ;   true
		)
	; true
	),
	(Ch2=1 -> 
		((cluster(Clust,N),Clust\=Cl1,Clust\=Cl2) ->
			once(cluster(Clc,N)),
			remove_crosspath_bypoint(1,C,Clc,OnlySuccL,SignABc,XA,YA,XB,YB,Xc,Yc)
		; true)
	; true
	),
	N1 is N+1,
	remove_cross_points(Id,XA,YA,XB,YB,N1,L,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2).

check_sign_direction(Direction,Sign):-
	(Direction="<" ->
			(Sign<0 -> true;fail)
		; 	(Sign>0 -> true;fail)
	).

remove_crosspath_bypoint(_,_,_,[],_,_,_,_,_,_,_).
remove_crosspath_bypoint(N,C,Clc,[_|OnlySuccL],SignABc,XA,YA,XB,YB,XC,YC):-
	((cluster(Clust,N),Clc\=Clust) ->
		once(point(N,Xh,Yh)),
		SignAC is (Yh-YA)*(XC-XA) - (Xh-XA)*(YC-YA),
		SignBC is (Yh-YC)*(XB-XC) - (Xh-XC)*(YB-YC),
		SignABh is (Yh-YA)*(XB-XA) - (Xh-XA)*(YB-YA),
		(check_sign_eq(SignABc,SignAC,SignBC,SignABh) ->
	        exclude(C,N)
	    ;   true
		)
	; true
	),
	N1 is N+1,
	remove_crosspath_bypoint(N1,C,Clc,OnlySuccL,SignABc,XA,YA,XB,YB,XC,YC).


check_sign_eq(SignABc,SignAC,SignBC,SignABh):-
	(SignABc < 0 ->
			((SignAC>0,SignBC>0,SignABh>0) -> true;fail)
		; 	((SignAC<0,SignBC<0,SignABh<0) -> true;fail)
	).