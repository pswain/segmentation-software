function obj=makeAbsEdge(obj,regionObj)
    % makeAbsEdge --- creates the abs edge image field
    %
    % Synopsis:  obj = makeAbsEdge (obj, regionObj)   
    %                        
    % Input:     obj = an object of a onecell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a onecell class

    % Notes:     For cells in regions that are not split (by watershed),
    %            simply copies the AbsEdgeImage property of the region. For
    %            split cells calculates edges within the bounding box
    %            defined by obj.ThisCell using regionObj.AbsImage
    
    if isempty (obj.CatchmentBasin)
        obj.RequiredImages.AbsEdgeImage=regionObj.RequiredImages.AbsEdgeImage;
    else%region is split into catchment basins
        if isempty (obj.TopLeftThisCellx)
            obj=makeBoundingBox(obj, regionObj);
        end
        if ~isfield(regionObj.RequiredImages,'AbsImage')
            if ~isfield(obj.RequiredImages,'SmallTarget')
                obj.RequiredImages.SmallTarget=obj.makeSmall(regionObj.Target);
            end
            smallAbs=localabs(obj.RequiredImages.SmallTarget);
        else
            smallAbs=obj.makeSmall(regionObj.RequiredImages.AbsImage); 
        end
        smallAbsEdge=edge(smallAbs,'Canny',[0.01 0.3]);
        obj.RequiredImages.AbsEdgeImage=false(size(regionObj.Target));
        obj.RequiredImages.AbsEdgeImage(obj.TopLeftThisCelly:obj.TopLeftThisCelly+obj.yThisCellLength-1,obj.TopLeftThisCellx:obj.TopLeftThisCellx+obj.xThisCellLength-1)=smallAbsEdge;                            
        obj.RequiredImages.AbsEdgeImage(obj.RequiredImages.ThisCell==0)=0;        
    end
end