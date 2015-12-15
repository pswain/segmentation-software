function [deleted outerImage closest]=deleteOuter(varargin)
    % deleteOuter --- Removes the outermost edge object from obj.EdgeImage
    %
    % Synopsis:  [deleted outerImage closest] = deleteOuter(edgeImage, 0)
    %            [deleted outerImage closest] = deleteOuter(edgeImage, deleteOuterMethod, thisCell)
    %                        
    % Input:     edgeImage = 2d logical matrix, image showing the detected edges in an image to be segmented
    %            deleteOuterMethod = logical, 0 to delete object nearest to edge of image, 1 to delete furthest away from centroid
    %            thisCell = 2d logical matrix, image showing the approximate position of the target cell within the image region
    %
    % Output:    deleted = 2d logical matrix, edge image with the outer object deleted
    %            outerImage = 2d logical matrix, image showing only the outer object
    %            closest = integer, index to the outer object in the result of regionprops(edgeImage)

    % Notes:     This is defined as a static method (not requiring an
    %            instance of the class) so that it can be used to delete
    %            the outer object from different edge images - eg
    %            EdgeImage and AbsEdgeImage. When method 0 (nearest to 
    %            edge) is used then the third input (thisCell) is only
    %            required for cells in regions that have been split by the
    %            watershed method.
    edgeImage=varargin{1};
    deleteOuterMethod=varargin{2};
    %Method 1 requires the third input - use method 0 if that is not
    %supplied
    if deleteOuterMethod==1 && nargin==2
        deleteOuterMethod=0; 
    end
    if nargin>2
        thisCell=varargin{3};
    end
    
    %first deal with the situation of a blank input - ie all pixels zero
    if any(edgeImage)==0
        deleted=edgeImage;
        outerImage=edgeImage;
        closest=1;
        return
    end
    
    objs=regionprops(edgeImage,'BoundingBox','Image','PixelList');      
    %deleteOuterMethod - is zero for method nearestToEdge and 1 for method furthestFromCentroid
    
    switch deleteOuterMethod
        case 0%deletes object closest to the side of the image
            if nargin==2
                [means closest]=cellsegmethods.FindOuter.nearestToEdge(edgeImage);%finds the index (in the regionprops structure) of the object nearest the the edge of the image
            else
                [means closest]=cellsegmethods.FindOuter.nearestToEdge(edgeImage,thisCell);%finds the index (in the regionprops structure) of the object nearest the the edge of the bounding box defined by thisCell
            end
                deleted=edgeImage;
                [outer]=objs(closest).Image;
                boxs=vertcat(objs.BoundingBox);
                outerImage=zeros(size(edgeImage));
                topleftxouter=ceil(boxs(closest,1));
                topleftyouter=ceil(boxs(closest,2));
                lengthyouter=size(outer,1)-1;
                lengthxouter=size(outer,2)-1;
                outerImage(topleftyouter:(topleftyouter+lengthyouter),topleftxouter:(topleftxouter+lengthxouter))=outer;
                deleted(outerImage==1)=0;
        case 1%method is furthestFromCentroid
            [closest outerImage meandist]=cellsegmethods.FindOuter.furthestFromCentroid(edgeImage, thisCell);
            deleted=edgeImage;
            deleted(outerImage==1)=0;
    end


    

end