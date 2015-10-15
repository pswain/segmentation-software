function LogicalResult = GetNearest(Point,Vector)
%give the euclidean distance between the entries in the nx2 matrix [Y X]
%and the 1x2 point [Ypoint Xpoint]. Return a logical matrix of which points
%are the nearest (doubles allowed)

EuclideanDistance = (Vector(:,1) - Point(1)).^2 + (Vector(:,2) - Point(2)).^2;

LogicalResult = EuclideanDistance==min(EuclideanDistance,[],1);


end
