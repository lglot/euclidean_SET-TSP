%% BOOLEAN USED TO CHOICE CONSTRAINTS TO APPLY:
%% Ch1 -> clockwise (Clockwise constraint: propagation of predecessors before instantiation) 
%% Ch2 -> CrossAbsence (Ch2=true does not admit crossing)
%% Ch3 -> Sort (Sorted visit as convex hull)

:-[pred_prog].
:-[sortedConstraintTsp].

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
	%
	(once(member(I,HullClusterId)),Ch3=1,nonmember(I,ConcaveCluster) ->
		sortConstraint(I,SuccClusteredL,HullClusterId,ConcaveCluster,Direction)
	; true
	),
	%
	ic_global:sumlist(SuccClusteredL,Somma),
	(var(Somma) ->
			suspend(nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2),5,Somma->suspend:inst)
		; 	nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2)
	),
	
	Inext is I + 1,
	nocrossing_and_clockwise1(Inext,BSCl,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2,Ch3).


nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2):-
	once(member(c(IdNode,1),BSC)),
	nth1(IdNode,OnlySuccL,Succ),
	once(point(IdNode,X0,Y0)),
	once(point(Succ,X1,Y1)),
	once(cluster(Cl1,IdNode)),
	once(cluster(Cl2,Succ)),
	remove_left_and_cross_points(IdNode,X0,Y0,X1,Y1,1,OnlySuccL,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2).


remove_left_and_cross_points(_,_,_,_,_,_,[],_,_,_,_,_,_,_,_).
remove_left_and_cross_points(Id,XA,YA,XB,YB,N,[C|L],OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2):-
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
		((cluster(Clust,N)) ->
			once(cluster(Clc,N)),
			remove_crosspath_bypoint(1,C,Clc,OnlySuccL,SignABc,XA,YA,XB,YB,Xc,Yc,Cl1,Cl2)
		; true)
	; true
	),
	N1 is N+1,
	remove_left_and_cross_points(Id,XA,YA,XB,YB,N1,L,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction,Ch1,Ch2).

check_sign_direction(Direction,Sign):-
	(Direction="<" ->
			(Sign<0 -> true;fail)
		; 	(Sign>0 -> true;fail)
	).

remove_crosspath_bypoint(_,_,_,[],_,_,_,_,_,_,_,_,_).
remove_crosspath_bypoint(N,C,Clc,[_|OnlySuccL],SignABc,XA,YA,XB,YB,XC,YC,Cl1,Cl2):-
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
	remove_crosspath_bypoint(N1,C,Clc,OnlySuccL,SignABc,XA,YA,XB,YB,XC,YC,Cl1,Cl2).


check_sign_eq(SignABc,SignAC,SignBC,SignABh):-
	(SignABc < 0 ->
			((SignAC>0,SignBC>0,SignABh>0) -> true;fail)
		; 	((SignAC<0,SignBC<0,SignABh<0) -> true;fail)
	).