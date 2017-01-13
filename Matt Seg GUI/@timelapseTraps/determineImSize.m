function imSize = determineImSize(cTimelapse,cellVision_pixel_size)
% imSize = determineImSize(cTimelapse,cellVision_pixel_size)
% 
% determines the appropriate size for imSize from rawImSize, the pixel_size
% given for the cTimelapse and the pixel_size given for the cellVision
% model used to process it. 
%
% cellVision_pixel_size     -    the pixel size of the cellVision model
%                                which will be used to process the
%                                timelapse. 
%                                this can also be a cellVision model, in
%                                which case the pixel_size is extracted.
%
% Image will be rescaled so that the scaled image pixel size is consistent
% with the cellVision pixel size. This is achieved by setting the
% rawImSize of the cTimelapse.
% 
% See also, TIMELAPSETRAPS.RETURNSINGLETIMEPOINT,
% EXPERIMENTTRACKING.SETIMSIZEALL

if isa(cellVision_pixel_size,'cellVision')
    cellVision_pixel_size = cellVision_pixel_size.pixelSize;
end

imSize = round(cTimelapse.rawImSize*cTimelapse.pixelSize/cellVision_pixel_size);
cTimelapse.imSize = imSize;

end