:-[pred_prog].

nocrossing_and_clockwise(BoolSucc,OnlySuccL,HullClusterId,ConcaveCluster,PredL,Direction):-
	%%Propagazione predecessori del senso orario prima del labeling
	pred_to_succ_propagation(1,PredL,OnlySuccL,HullClusterId,ConcaveCluster,Direction),
	nocrossing_and_clockwise1(1,BoolSucc,OnlySuccL,HullClusterId,ConcaveCluster,Direction).

%% Predicato iterato su ogni cluster I
nocrossing_and_clockwise1(_,[],_,_,_,_).
nocrossing_and_clockwise1(I,[BSC|BSCl],OnlySuccL,HullClusterId,ConcaveCluster,Direction):-
	
	%Filtro per creare una lista (SuccClusteredL) contenente solo le variabili successori dei nodi del cluster I
	(param(I),foreach(Succ,OnlySuccL), count(ID,1,_), fromto(SuccClusteredL,Out,In,[]) do
		cluster(I,ID) -> Out=[Succ|In] ; Out=In
	),
	
	%% Applico vincolo della visita ordinata sui nodi del cluster 
	%% e che non siano all'interno della convex hull interna
	(once(member(I,HullClusterId)),nonmember(I,ConcaveCluster) ->
		sortConstraint(I,SuccClusteredL,HullClusterId,ConcaveCluster,Direction)
		%true
	; true
	),

	%% Sospensioni sui cluster fino alla loro istanziazione (quindi quando è stato scelto il nodo da visitare del
	%% del cluster e di conseguenza gli altri non vengono visitati)
	%% A tale scopo viene usata una variabile somma che rappresenta la somma delle variabili successore del cluster e
	%% che verrà istanziata nel momento in cui verrà scelto il nodo visitato
	ic_global:sumlist(SuccClusteredL,Somma),
	(var(Somma) ->
			suspend(nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction),5,Somma->suspend:inst)
		; 	nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction)
	),
	
	Inext is I + 1,
	nocrossing_and_clockwise1(Inext,BSCl,OnlySuccL,HullClusterId,ConcaveCluster,Direction).

%% Vincolo che impone che i nodi sulla convex hull interna vengono visitati in ordine
sortConstraint(IdCluster,SuccClusteredL,HullClusterId,ConcaveCluster,Direction):-
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

%% Prelevo informazioni sull'arco istanziato Node->Succ
nocrossing_and_clockwise_propagation(BSC,OnlySuccL,HullClusterId,ConcaveCluster,Direction):-
	%% Get ID of Node
	once(member(c(IdNode,1),BSC)),
	%% Get successor of Node
	nth1(IdNode,OnlySuccL,Succ),
	once(point(IdNode,X0,Y0)),
	once(point(Succ,X1,Y1)),
	once(cluster(Cl1,IdNode)),
	once(cluster(Cl2,Succ)),
	remove_cross_points(IdNode,X0,Y0,X1,Y1,1,OnlySuccL,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction).

%% Funzione che rimuove dal dominio dei punti che sono a sinistra del segmento PA->PB il punto PA
%% e che rimuove dal dominio di tutti i punti non appartenenti ai cluster di PA e PB tutti i punti che genererebbero
%% un incrocio se raggiunti dai primi
remove_cross_points(_,_,_,_,_,_,[],_,_,_,_,_,_).
remove_cross_points(Id,XA,YA,XB,YB,N,[C|L],OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction):-
	once(point(N,Xc,Yc)),
	SignABc is (Yc-YA)*(XB-XA) - (Xc-XA)*(YB-YA),
	((cluster(I,Id),once(member(I,HullClusterId)),nonmember(I,ConcaveCluster)) ->
		(check_sign_direction(Direction,SignABc) ->
				exclude(C,Id)
		    ;   true
		)
	; true
	),
	((cluster(Clust,N),Clust\=Cl1,Clust\=Cl2) ->
		once(cluster(Clc,N)),
		remove_crosspath_bypoint(1,C,Clc,OnlySuccL,SignABc,XA,YA,XB,YB,Xc,Yc)
	; true),
	N1 is N+1,
	remove_cross_points(Id,XA,YA,XB,YB,N1,L,OnlySuccL,Cl1,Cl2,HullClusterId,ConcaveCluster,Direction).

check_sign_direction(Direction,Sign):-
	(Direction="<" ->
			(Sign<0 -> true;fail)
		; 	(Sign>0 -> true;fail)
	).

%% Rimuove tutti i punti dal dominio di N che generano un incrocio con PA->PB se raggiunti da N
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