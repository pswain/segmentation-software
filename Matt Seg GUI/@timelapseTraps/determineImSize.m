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

if isempty(cTimelapse.pixelSize)
     prompt = {'Enter the size of the pixels in this image in micrometers (for swainlab microscopes at 60x magnification this is 0.263 micrometers)'};
    dlg_title = 'Pixel Size';
    num_lines = 1;
    def = {'0.263'};
    answer = inputdlg(prompt,dlg_title,num_lines,def,struct('Interpreter','tex'));
    cTimelapse.pixelSize=str2double(answer{1});
end

imSize = round(cTimelapse.rawImSize*cTimelapse.pixelSize/cellVision_pixel_size);
cTimelapse.imSize = imSize;

end