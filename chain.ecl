/* Monotone Chain Convex Hull Algorithm */
/* Adapted to ECLiPSe from
/* http://www.algorithmist.com/index.php/Monotone_Chain_Convex_Hull.py */


% clockwise_turn(Pa, Pb, Pc) is true if Pa is strictly to the right of the
% directed line from Pb to Pc.
clockwise_turn(p(Xa,Ya),p(Xb,Yb),p(Xc,Yc)):-
  (Xb-Xa) * (Yc-Ya) - (Xc-Xa) * (Yb-Ya) < 0.0.

% c_clockwise_turn(Pa, Pb, Pc) is true if Pa is strictly to the left of
% the directed line from Pb to Pc.
% Counter-clockwise
c_clockwise_turn(p(Xa,Ya),p(Xb,Yb),p(Xc,Yc)):-
    (Xb-Xa) * (Yc-Ya) - (Xc-Xa) * (Yb-Ya) > 0.0.

% Sort the points lexicographically (tuples are compared lexicographically).
% Sort the points of P by x-coordinate (in case of a tie, sort by y-coordinate).
% Example: Points = [p(0,2),p(1,4),p(1,0),p(0,4),p(2,1)]
% Sorted = [p(0,2),p(0,4),p(1,0),p(1,4),p(2,1)]
lexicograph_sort(Points,Sorted):-
  sort(0,=<,Points,Sorted).

% lower(Points,Lower) is true if Lower are the vertices in the lower
% part of the convex hull
lower([P],[P]).
lower([P1,P2|Tail],Lower):-
  lower_1(Tail,[P2,P1],2,Lower).

lower_1([],L,_,L).
lower_1([P|T1],L1,N,L2):-
  (N > 1, L1 = [A,B|T2], clockwise_turn(B,A,P) ->
    N1 is N - 1,
    lower_1([P|T1],[B|T2],N1,L2)
  ; N1 is N + 1,
    lower_1(T1,[P|L1],N1,L2)
  ).

% upper(Points,Lower) is true if Upper are the vertices in the upper
% part of the convex hull
upper([P],[P]).
upper([P1,P2|Tail],Upper):-
  upper_1(Tail,[P2,P1],2,Upper).

upper_1([],L,_,L).
upper_1([P|T1],L1,N,L2):-
    %MG: N mi sembra inutile: rappresenta il numero di elementi nella hull, ma viene usato solo per vedere
    % se la lista ha piu` di 1 elemento!
  (N > 1, L1 = [A,B|T2], c_clockwise_turn(B,A,P) ->
    N1 is N - 1,
    upper_1([P|T1],[B|T2],N1,L2)
  ; N1 is N + 1,
    upper_1(T1,[P|L1],N1,L2)
  ).

% concatenate(A,B,C) is true if list C is the result of appending
% list B to list A where the first element of A is removed and
% list A is reversed
% Example:  A = [1,2,3], B = [4,5,6], C = [3,2,4,5,6]
concatenate([_|T],U,Result):-
  m_reverse(T,L,[]),
  m_append(L,U,Result).

m_reverse([],L,L).
m_reverse([H|T],L,R) :-
  m_reverse(T,L,[H|R]).

m_append([],X,X).
m_append([X|L1],L2,[X|L3]):-
  m_append(L1,L2,L3).

% hull(Points, ConvexHullVertices) is true if Points is a list of points
% in the form p(X,Y), and ConvexHullVertices are the vertices in the form
% p(X,Y) of the convex hull of the Points, in clockwise order, starting
% and ending at the smallest point (as determined by X-values, and by
% Y-values to resolve ties).
hull(Points,ConvexHullVertices):-
  hull(Points,ConvexHullVertices,_,_).
hull(Points,ConvexHullVertices,L,U):-
  lexicograph_sort(Points,S), % Questo potrei farlo anche fuori !!!
  hull_sorted(S,ConvexHullVertices,L,U).

hull_sorted(S,ConvexHullVertices,L,U):-
  lower(S,L),
  upper(S,U),
  concatenate(U,L,ConvexHullVertices).

hull_sorted(S,ConvexHullVertices):-
    hull_sorted(S,ConvexHullVertices,_,_).

% dynamic_hull_remove(Points,ToDelete,OldUpper,OldLower,NewUpper,NewLower,NewHull)
% Given a list of points Points THAT IS ASSUMED SORTED!
% a point to delete: ToDelete (it is assumed that it is a point in the old hull)
% The old lists OldUpper and OldLower
% Compute the new hull.
% All points are in the form p(X,Y)
% PUO` ESSERE MIGLIORATO, GUARDANDO MEGLIO GLI ALGORITMI LOWER E UPPER, CONSIDERANDO CHE HO GIA` LA PRIMA E L'ULTIMA PARTE DELLA HULL
% Intanto faccio questa prima versione, che risparmia di eseguire uno fra lower e upper
dynamic_hull_remove(S,ToDelete,OldUpper,OldLower,NewUpper,NewLower,NewHull):-
%    lexicograph_sort(Points,S), Spostato fuori
    (memberchk(ToDelete,OldUpper)
    ->  upper(S,NewUpper),
        NewLower = OldLower
    ;   lower(S,NewLower),
        NewUpper = OldUpper
    ),
    concatenate(NewUpper,NewLower,NewHull).
    %occhio che ci sono punti in comune; nella mg c'e` il punto 2, che e` uno dei primi!
