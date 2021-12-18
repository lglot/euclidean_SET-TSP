sortConstraint(IdCluster,SuccClusteredL,HullClusterId,ConcaveCluster,Direction):-
	subtract(HullClusterId,ConcaveCluster,ClusterToVisitInOrder),
	head(ClusterToVisitInOrder,Head),
    append(ClusterToVisitInOrder,[Head],ClusterToVisitInOrder2),
	head(HullClusterId,Head),
    append(HullClusterId,[Head],ClusterToVisitInOrder2),
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