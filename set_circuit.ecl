% From ECLiPSe 7.0_45 sources

:- module(set_circuit).

% --------------- ic_constraints -------------------------

:- lib(ic).
:- lib(ic_kernel).

:- export set_circuit/2.

set_circuit(SuccC, NCluster) :-
    %writeln(error, "**WARNING (dev): Using set_circuit"),
    (nonvar(NCluster) -> true ; throw(error(instantiation_error, set_circuit/2))),
	eval_to_array(SuccC, Succz),
	(nonvar(Succz) -> true ; throw(error(instantiation_error, set_circuit/2))),
	arity(Succz, N),
	(N > NCluster -> true ; throw(error(instantiation_error, set_circuit/2))),
	Succz #:: 1..N,
	
	%PathLen is NCluster + 1, % add depot
	
	%% Prevent node 1 (depot) from having itself as successor 
	%arg(1, Succz, Next1),
	%exclude(Next1, 1),
	
	(N<2 -> true ;
	    (for(Start,1,N), param(Succz,NCluster) do
		arg(Start, Succz, Next),
		no_subtour(Start, Next, Succz, NCluster),
		wake
	    )
	).


delay no_subtour(_Start, This,_Succz,_NLeft) if var(This).
no_subtour(Start, This, Succz, NLeft0) :-
	(Start = This ->
        true
    ;
        arg(This, Succz, Next),
        NLeft is NLeft0-1,
        ( NLeft > 1 ->
            exclude(Next, Start),
            no_subtour(Start, Next, Succz, NLeft)
        ;
            Next = Start
        )
    ).

