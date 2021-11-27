
%% Effettua la propagazione per il senso orario usando i predecessori:
%% Per ogni predecessore p di N controllo ogni successore di N, 
%% se l'angolo tra gli archi tra il predecessore e tutti i successori di N non rispetta 
%% il vincolo del senso orario allora possoro rimuovere p dal dominio dei predecessori di N
pred_to_succ_propagation(_,[],[],_,_,_).
pred_to_succ_propagation(N,[PredVar|PL],[SuccVar|SL],HullClusterId,ConcaveCluster,Direction):-
	once(point(N,Xn,Yn)),
	((cluster(Clust,N),once(member(Clust,HullClusterId)),nonmember(Clust,ConcaveCluster)) ->
		pred_to_succ_constraint(Xn,Yn,PredVar,SuccVar,Direction)
	; true
	),
	Next is N+1,
	pred_to_succ_propagation(Next,PL,SL,HullClusterId,ConcaveCluster,Direction).
	
pred_to_succ_constraint(Xn,Yn,PredVar,SuccVar,Direction):-
	get_domain_as_list(PredVar,PredDomain),
	get_domain_as_list(SuccVar,SuccDomain),
	(param(Xn),param(Yn), param(PredVar),param(SuccDomain),param(Direction),foreach(Pred,PredDomain) do
		once(point(Pred,Xp,Yp)),
		(check_remove_left_points(Xn,Yn,Xp,Yp,SuccDomain,Direction) ->
			exclude(PredVar,Pred)
		; true
		)
	),
	(var(PredVar) ->
		suspend(pred_to_succ_constraint(Xn,Yn,PredVar,SuccVar,Direction),5,[SuccVar->ic:any,PredVar->suspend:inst])
	; true
	).

check_remove_left_points(_,_,_,_,[],_).
check_remove_left_points(Xn,Yn,Xp,Yp,[Succ|SuccDomain],Direction):-
	once(point(Succ,Xs,Ys)),
	Sign is (Yp-Yn)*(Xs-Xn) - (Xp-Xn)*(Ys-Yn),
	(check_sign_direction(Direction,Sign) ->
		check_remove_left_points(Xn,Yn,Xp,Yp,SuccDomain,Direction)
	; fail
	).