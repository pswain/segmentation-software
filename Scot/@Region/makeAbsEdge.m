function obj= makeAbsEdge(obj)
    % makeabsedge --- calculates obj.AbsImage and obj.AbsEdgeImage
    %
    % Synopsis:  obj = makeabsedge (obj)
    %
    % Input:     obj = an object of a region class
    %
    % Output:    obj = an object of a region class
    
    %Notes:      Uses the localabs function which uses a local mean (in a
    %30 pixel square). Can play with this parameter to try to improve.
    obj.RequiredImages.AbsImage=localabs(obj.Target,30);
    obj.RequiredImages.AbsEdgeImage = edge(obj.RequiredImages.AbsImage,'canny',[0.01,0.3]);
end