function obj=calculateWatershed(obj)
    % calculatewatershed --- separates region into catchment basins using the watershed transform
    %
    % Synopsis:  obj = calculatewatershed (obj)
    %
    % Input:     obj = an object of a region class
    %            
    % Output:    obj = an object of a region class

    % Notes:     Separation is based on the binary obj.Bw image, which
    %            should give a rough approximation of the positions and
    %            shapes of cells. The depth parameter (obj.Depth) affects
    %            the the probability offinding a watershed line - low depth
    %            = more lines. Populates the Region object fields
    %            obj.Watershed and obj.NumBasins
    %            
    bw=1-obj.Bw;
    d=bwdist(bw);
    f=imhmin(1-d,obj.Depth);
    obj.Watershed=watershed(f);
    obj.NumBasins=max(obj.Watershed(:));
end