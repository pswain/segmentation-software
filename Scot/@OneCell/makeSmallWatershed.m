function obj=makeSmallWatershed(obj, regionObj)
    % makeSmallWatershed --- creates the smallWatershed property of OneCell object
    %
    % Synopsis:  obj = makeSmallWatershed (obj, regionObj)
    %                        
    % Input:     obj = an object of a OneCell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     The SmallWatershed property shows the watershed image
    %            (that splits the region into individual cells) within the
    %            bounding box defined by the ThisCell image.
    x=obj.RequiredFields.BoundingBox(1);
    y=obj.RequiredFields.BoundingBox(2);
    xLength=obj.RequiredFields.BoundingBox(3);
    yLength=obj.RequiredFields.BoundingBox(4);

    obj.RequiredImages.SmallWatershed=regionObj.RequiredImages.Watershed(y:y+yLength-1,x:x+xLength-1);
