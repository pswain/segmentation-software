function loadTimelapse(cTimelapseOmero,searchString,image_rotation,trapsPresent,timepointsToLoad,pixel_size)
% loadTimelapse(cTimelapseOmero,searchString,image_rotation,trapsPresent,timepointsToLoad,pixel_size)
%
% populates the cTimpoint field, determining how many timepoints there are
% in the timelapse by identifying images who's name contains the searchString.
%
% INPUTS
% 
% cTimelapseOmero       -  object of the timelapseTrapsOmero class.
% searchString          -  string.the string that appears in each image
%                          associated with a particular timepoint
% image_rotation        -  counter clockwise rotation of images (in
%                          degrees) to perform when an image is requested.
%                          Generally rotated to align traps with the base
%                          trap in the cellVision model.
% trapsPresent          -  a boolean that states whether there are traps
%                          present. Used at various stages of the
%                          processing.
% timepointsToLoad      -  unused in Omero case but kept for compatibility.
% pixel_size            -  width of a pixel in the image in micrometers.
%                          Default is 0.262 - the value for the swainlab
%                          miscroscopes at 60X.
% 
% 
% Populates the cTimepoints structure using information from Omero.
%
% other properties:
%   - rotation
%   - trapsPresent
%   - imSize
%   - rawImSize
% are also populated, by GUI if not provided.
%
% See also EXPERIMENTTRACKINGOMERO.CREATETIMELAPSEPOSITIONS

cTimepointTemplate = cTimelapseOmero.cTimepointTemplate;

cTimelapseOmero.cTimepoint = cTimepointTemplate;

%Correct Z position - load image from the middle of the stack
pixels=cTimelapseOmero.omeroImage.getPrimaryPixels;
sizeT=pixels.getSizeT().getValue();
cTimelapseOmero.cTimepoint(sizeT).filename=[];%This makes sure cTimepoint has the correct length
cTimelapseOmero.timepointsToProcess = 1:sizeT;

%Load first timepoint of this cTimelapse to fill out the remaining
%details
image=cTimelapseOmero.returnSingleTimepointRaw(1,find(strcmp(cTimelapseOmero.channelNames,searchString)));

cTimelapseOmero.initializeImageProperties(image,image_rotation,trapsPresent,pixel_size);


end

