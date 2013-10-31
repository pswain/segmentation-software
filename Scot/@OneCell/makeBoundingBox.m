function obj=makeBoundingBox(obj, regionObj)
    % makeBoundingBox --- records the coordinates of the bounding box defined by the object in obj.ThisCell
    %
    % Synopsis:  obj = makeBoundingBox(obj, regionObj)
    %                        
    % Input:     obj = an object of a OneCell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     Finds the coordinates using the regionprops function and
    %            populates the appropriate properties.
    
    if ~isfield(obj.RequiredImages,'ThisCell')
        obj=obj.makeThisCell(regionObj);
    end
    %define bounding box of watershedded region
    if isempty(obj.TopLeftThisCellx)
        splitcells=regionprops(obj.RequiredImages.ThisCell,'BoundingBox');
        splitbb=vertcat(splitcells.BoundingBox);
        if numel(splitbb)>0
            obj.TopLeftThisCellx=ceil(splitbb(1));
            obj.TopLeftThisCelly=ceil(splitbb(2));
            obj.xThisCellLength=round(splitbb(3));
            obj.yThisCellLength=round(splitbb(4));
        else
            obj.TopLeftThisCellx=1;
            obj.TopLeftThisCelly=1;
            obj.xThisCellLength=size(obj.RequiredImages.ThisCell,2);
            obj.yThisCellLength=size(obj.ThisCell,1);
        end
    end

end