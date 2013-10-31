function obj=makeEdgeImage(obj,regionObj)
    % makeEdgeImage --- creates the edge image field
    %
    % Synopsis:  obj = makeEdgeImage(obj, regionObj)   
    %                        
    % Input:     obj = an object of a onecell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a onecell class

    % Notes:     For cells in regions that are not split (by watershed),
    %            simply copies the EdgeImage property of the region. For
    %            split cells calculates edges within the bounding box
    %            defined by obj.ThisCell
    
    
    if isempty (obj.CatchmentBasin)         
        %First make sure the region object has a defined edge image
        if ~isfield(regionObj.RequiredImages,'EdgeImage')
            regionObj.RequiredImages.EdgeImage=edge(regionObj.Target,'Canny',[0.01 0.3]);
        end
        obj.RequiredImages.EdgeImage=regionObj.RequiredImages.EdgeImage;
    else%region is split into catchment basins
        if ~isfield(obj.RequiredImages,'SmallTarget')
            obj.RequiredImages.SmallTarget=obj.makeSmall(regionObj.Target);
        end
        if ~isfield(obj.RequiredImages, 'ThisCell')
            obj=obj.makeThisCell(regionObj);          
        end
        
        edgeImg=edge(obj.RequiredImages.SmallTarget,'Canny',[0.01 0.3]);
        obj.RequiredImages.EdgeImage=false(size(regionObj.Target));
        x=obj.RequiredFields.BoundingBox(1);
        y=obj.RequiredFields.BoundingBox(2);
        xLength=obj.RequiredFields.BoundingBox(3);
        yLength=obj.RequiredFields.BoundingBox(4);   
        obj.RequiredImages.EdgeImage(y:y+yLength-1,x:x+xLength-1)=edgeImg;                            
        obj.RequiredImages.EdgeImage(obj.RequiredImages.ThisCell==0)=0;        
    end
end