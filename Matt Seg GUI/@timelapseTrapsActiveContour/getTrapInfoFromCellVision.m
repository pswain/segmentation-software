function ttacObject = getTrapInfoFromCellVision(ttacObject,cCellVision)
%method to extract trap infor from the cTimelapse and the cell Vision
%together. Need both since the exact locations of centers of the traps are
%dependent on the trap image, so need to find trap centers and make trap
%images in SegmentConsecutiveTimepoints with the same trap image.

if nargin<2 || isempty(cCellVision)


fprintf('please select cell vision model used to identify the cells in the timelapse: \n')

[CVname,CVpath] = uigetfile(pwd);

load(fullfile(CVpath, CVname),'cCellVision');

end

ttacObject.cCellVision = cCellVision;

ttacObject.TrapImage = cCellVision.cTrap.trapOutline;

[ttacObject.TrapPixelImage] = ACTrapFunctions.makeTrapPixelsFunction(cCellVision.cTrap.trapOutline);

ttacObject.TrapImageSize = size(cCellVision.cTrap.trapOutline);

%% get image dimensions

image = ttacObject.ReturnImage(1,1);

ttacObject.ImageSize = size(image);

clear('image');



end