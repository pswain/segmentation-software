function obj=makeThisCell(obj, regionObj)
    % makeThisCell --- creates the thisCell property of OneCell object
    %
    % Synopsis:  obj = makeThisCell(obj, regionObj)
    %                        
    % Input:     obj = an object of a OneCell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     For cells in regions that are not split (by watershed),
    %            simply copies the Bin property of the region. For
    %            split cells returns an image showing only the white pixels
    %            of the region's Bin image that are in this cell's catchment
    %            basin
    
    if isempty (obj.CatchmentBasin)
        obj.RequiredImages.ThisCell=regionObj.RequiredImages.Bin;
    else
        obj.RequiredImages.ThisCell=false(size(regionObj.Target));
        obj.RequiredImages.ThisCell(regionObj.RequiredImages.Watershed==obj.CatchmentBasin)=regionObj.RequiredImages.Bin(regionObj.RequiredImages.Watershed==obj.CatchmentBasin);
    end
end