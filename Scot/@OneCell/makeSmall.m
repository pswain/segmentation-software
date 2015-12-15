function smallImg=makeSmall(obj, image)
    % makeSmall --- returns the portion of an input image that lies within the bounding box defined by obj.ThisCell
    %
    % Synopsis:  smallImg = makeSmall(obj, image)
    %                        
    % Input:     obj = an object of a OneCell class
    %            image = 2d matrix, an image the size of the region that the cell is in
    %
    % Output:    smallImg = 2d matrix

    % Notes:     The coordinates of the bounding box must be defined before
    %calling this function and recorded in obj.RequiredFields.BoundingBox
    x=obj.RequiredFields.BoundingBox(1);
    y=obj.RequiredFields.BoundingBox(2);
    xLength=obj.RequiredFields.BoundingBox(3);
    yLength=obj.RequiredFields.BoundingBox(4);
    
    smallImg=image(y:y+yLength-1,x:x+xLength-1);
end