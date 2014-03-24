function ttacObject = getTrapInfoFromCellVision(ttacObject,varargin)
%method to extract trap infor from the cTimelapse and the cell Vision
%together. Need both since the exact locations of centers of the traps are
%dependent on the trap image, so need to find trap centers and make trap
%images in SegmentConsecutiveTimepoints with the same trap image.

if nargin>1
    cCellVision = varargin{1};
else

fprintf('please select cell vision model used to identify the cells in the timelapse: \n')

[CVname,CVpath] = uigetfile(pwd);

load(fullfile(CVpath, CVname),'cCellVision');
end
%this file should only have the cCellVision variable

ttacObject.cCellVision = cCellVision;

ttacObject.TrapImage = cCellVision.cTrap.trapOutline;

ttacObject.TrapPixelImage = ACTrapFunctions.makeTrapPixelsFromBinaryFunction(cCellVision.cTrap.trapOutline,varargin{2:end});

ttacObject.TrapImageSize= size(cCellVision.cTrap.trapOutline);

%% get image dimensions

image = ttacObject.ReturnImage(1,1);

[imageY,~] = size(image);

tempTrapCentre = false(size(image));

clear('image');

%% put 

for TP=1:length(ttacObject.TimelapseTraps.cTimepoint)
    if ~isempty(ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations)
        CentrePixels = imageY*(round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).xcenter]-1)) +  round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).ycenter]);
    else
        CentrePixels = [];
    end
    
    tempTrapCentre(CentrePixels) = true;
    
    ttacObject.TrapLocation{TP} = sparse(tempTrapCentre);
    
    tempTrapCentre(CentrePixels) = false;
    
end


end