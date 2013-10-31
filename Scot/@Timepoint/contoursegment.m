function obj=contoursegment(obj,mask)
    % countoursegment --- segmentation of a timepoint using contour methods alone. NOT YET IMPLEMENTED
    %
    % Synopsis:  obj=contoursegment(obj,mask)
    %
    % Input:     obj = an object of a timepoint class
    %            mask = 2d boolean matrix, defines initial contours
    % Output:    obj = an object of a timepoint class

    % Notes:     For contour-only segmentation - not yet written. Mask
    %            would be the segmentation result from the previous
    %            timepoint, or for the first timepoint an edge-segmented
    %            result. Loop through the objects in the mask image then
    %            apply contour methods to those regions
    disp('Contour segment not yet implemented');           
end