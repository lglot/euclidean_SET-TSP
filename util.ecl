head([],[]).
head([X|_],X).

get_tsp(NCluster,SuccL,Tsp):-
	NCluster1 is NCluster + 1,
	length(Tsp,NCluster1),
	head(SuccL,FirstArc),
	get_tsp1(FirstArc,SuccL,1,Tsp).
get_tsp1(arc(X,X),SuccL,I,Tsp):-!,
	Inext is I + 1,
	nth1(Inext,SuccL,Arc),
	get_tsp1(Arc,SuccL,Inext,Tsp).
get_tsp1(_,_,_,[]):-!.
get_tsp1(arc(Node,Succ),SuccL,_,[X|TspL]):-
	Node\=Succ,
	X = Node,
	nth1(Succ,SuccL,Arc),
	get_tsp1(Arc,SuccL,_,TspL).

remove_duplicates([], []).
remove_duplicates([Head | Tail], Result) :-
    member(Head, Tail), !,
    remove_duplicates(Tail, Result).
remove_duplicates([Head | Tail], [Head | Result]) :-
    remove_duplicates(Tail, Result).

list_empty([], true).
list_empty([_|_], false).

samelist([], []).
samelist([H1|R1], [H2|R2]):-
    H1 = H2,
    same(R1, R2).

write_list(Name,L):-
	write(Name),
	write(" : ["),
	write_loop(L),
	write("]\n").

write_loop([X]):- write(X),!.
write_loop([H|T]):-
	write(H),
	write(" ,"),
	write_loop(T).
