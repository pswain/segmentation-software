function [OuterDeleted OuterImage]=DeleteOuter(edgeImage,thisCell)

       %If statement to avoid errors in case of a blank input image
       if any(edgeImage)==0
            OuterDeleted=edgeImage;
            OuterImage=edgeImage;
            return
       end
       objs=regionprops(edgeImage,'BoundingBox','Image','PixelList');                   
       [closest obj.OuterImage meandist]=cellsegmethods.FindOuter.furthestFromCentroid(edgeImage, thisCell);
       OuterDeleted=edgeImage;
       obj.OuterDeleted(obj.OuterImage==1)=0;
end
