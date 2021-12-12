
distance:-
    findall(p(ID,X,Y),point(ID,X,Y),Points),
    calcola(Points,Points).

calcola([],_).
calcola([p(ID,X,Y)|L],Points):-
    calcolaloop(ID,X,Y,Points),
    calcola(L,Points).

calcolaloop(_,_,_,[]).
calcolaloop(ID1,X1,Y1,[p(ID2,X2,Y2)|L]):-
    (ID1\=ID2 ->
    D is (sqrt((X2-X1)^2 + (Y2-Y1)^2))*1000,
    DD is integer(round(D)),
    %writeln(cost(ID1,ID2,DD)),
    assert(cost(ID1,ID2,DD)),
    calcolaloop(ID1,X1,Y1,L)
    ; calcolaloop(ID1,X1,Y1,L)
    ).