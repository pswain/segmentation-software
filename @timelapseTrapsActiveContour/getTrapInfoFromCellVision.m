function ttacObject = getTrapInfoFromCellVision(ttacObject)
%method to extract trap infor from the cTimelapse and the cell Vision
%together. Need both since the exact locations of centers of the traps are
%dependent on the trap image, so need to find trap centers and make trap
%images in SegmentConsecutiveTimepoints with the same trap image.

fprintf('please select cell vision model used to identify the cells in the timelapse: \n')

[CVname,CVpath] = uigetfile('~/Matt\ Seg\ GUI/');

load([CVpath '/' CVname],'cCellVision');
%this file should only have the cCellVision variable

ttacObject.TrapPixelImage = ACTrapFunctions.makeTrapPixelsFromBinaryFunction(cCellVision.cTrap.trapOutline);

%% get image dimensions

image = imread(ttacObject.TimelapseTraps.cTimepoint(1).filename{1});

[imageY,~] = size(image);

tempTrapCentre = false(size(image));

clear('image');

%% put 

for TP=1:length(ttacObject.TimelapseTraps.cTimepoint)
    
    CentrePixels = imageY*(round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).xcenter]-1)) +  round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).ycenter]);
    
    tempTrapCentre(CentrePixels) = true;
    
    ttacObject.TrapLocation{TP} = sparse(tempTrapCentre);
    
    tempTrapCentre(CentrePixels) = false;
    
end

end