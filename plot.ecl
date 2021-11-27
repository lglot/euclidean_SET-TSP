:-lib(gnuplot).

plot_tsp(NCluster,Hull,InsideHull,Tsp,OutputFile):-
	(for(I,1,NCluster), 
		foreach(Cluster, ClusterList), 
		foreach(I,Colors), 
		foreach(points,With),
		foreach(2,PointSize),
		foreach(7,PointType),
		foreach(1,Linewidth),
		foreach(I,Titles),
		foreach(HullCluster,HullClusterList)
		do
		findall(p(X,Y),(cluster(I,N),point(N,X,Y)),Cluster),
		hull(Cluster,HullCluster)
	),
	

	(foreach(Id,Tsp), foreach(p(X,Y),CoordTsp) do
        once(point(Id,X,Y))
    ),

	
	(for(I,1,NCluster), 
		foreach(I,Colors2), 
		foreach(linespoints,With2),
		foreach(0,PointSize2),
		foreach(1,PointType2),
		foreach(1,Linewidth2),
		foreach(I,Titles2)
		do
		true
	),
	
	append([ClusterList,[Hull,InsideHull,CoordTsp],HullClusterList],Plot),
	append([With,[linespoints,linespoints,linespoints],With2],With1),
	append([Colors,[0,68,51],Colors2],Colors1),
	append([PointSize,[0,0,0],PointSize2],PointSize1),
	append([PointType,[1,1,1],PointType2],PointType1),
	append([Linewidth,[2,2,3],Linewidth2],Linewidth1),
	append([Titles,["convex hull","inside hull","set tsp"],Titles2],Titles1),

	(var(OutputFile) ->
		plot(Plot,[with:With1,pointsize:PointSize1,pointtype:PointType1,linetype:Colors1,linewidth:Linewidth1,title:Titles1]),!
	;	
		concat_string([OutputFile,".png"],OutputFile1),
		plot(Plot,[with:With1,pointsize:PointSize1,pointtype:PointType1,linetype:Colors1,linewidth:Linewidth1,title:Titles1],png,OutputFile1),!
	).