function ttacObject = getTrapInfoFromCellVision(ttacObject,cCellVision,which_cell_to_use)
%method to extract trap infor from the cTimelapse and the cell Vision
%together. Need both since the exact locations of centers of the traps are
%dependent on the trap image, so need to find trap centers and make trap
%images in SegmentConsecutiveTimepoints with the same trap image.

if nargin<2 || isempty(cCellVision)


fprintf('please select cell vision model used to identify the cells in the timelapse: \n')

[CVname,CVpath] = uigetfile(pwd);

load(fullfile(CVpath, CVname),'cCellVision');

end

if nargin<3 || isempty(which_cell_to_use)

    which_cell_to_use = 1;

end
%this file should only have the cCellVision variable

ttacObject.cCellVision = cCellVision;

if which_cell_to_use==1

    TrapIM = double(cCellVision.cTrap.trap1);
else
    TrapIM = double(cCellVision.cTrap.trap2);
end

[ttacObject.TrapPixelImage,ttacObject.TrapImage] = ACTrapFunctions.makeTrapPixelsFunction(TrapIM);

ttacObject.TrapImageSize = size(cCellVision.cTrap.trapOutline);

%% get image dimensions

image = ttacObject.ReturnImage(1,1);

[imageY,imageX] = size(image);

tempTrapCentre = false(size(image));

clear('image');

%% put 

offset = [4 0]; %[x off set and y off set]

if any(offset~=0)
    
    fprintf('\n\napplying an arbitrary offset - check the outcome of this procedure\n\n');
    
end

for TP=ttacObject.TimelapseTraps.timepointsToProcess;
    if ~isempty(ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations)
        CentrePixels = imageY*(round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).xcenter]-1 + offset(1))) +  round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).ycenter] + offset(2));
        CentrePixels(CentrePixels<1) = 1;
        CentrePixels(CentrePixels>(imageX*imageY)) = (imageX*imageY);
    else
        CentrePixels = [];
    end
    
    tempTrapCentre(CentrePixels) = true;

    ttacObject.TrapLocation{TP} = sparse(tempTrapCentre);
    
    tempTrapCentre(CentrePixels) = false;
    
end


end