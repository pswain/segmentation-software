function obj=changeDepth(obj,newdepth,defaults)
    % changedepth --- recalculates obj.Watershed on the basis of input depth, resegments the resulting region
    %
    % Synopsis:  obj = region3 (obj, newdepth, defaults)
    %
    % Input:     obj = an object of a region class
    %            newdepth = scalar, the new depth for calculating imhmin
    %            defaults = structure with default segmentation parameters
    %
    % Output:    obj = an object of a region class

    % Notes:     For use in editing segmentation results. Allows the effect
    %            of changing the depth to be tested.
    if isempty(obj.Defaults)
        obj.Defaults=defaults;
    end
    obj.Depth=newdepth;
    obj=calculateWatershed(obj);
    obj=segmentRegion(obj);
end