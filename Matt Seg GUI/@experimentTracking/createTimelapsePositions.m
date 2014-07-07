function createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,trapsPresent)


if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'DIC'});
end

if nargin<3 || strcmp(positionsToLoad,'all')
    positionsToLoad=1:length(cExperiment.dirs);
end
    
if nargin<4
    pixelSize=[];
end

if nargin<5
    image_rotation=[];
end

if nargin<6
    timepointsToLoad=[];
end


cExperiment.searchString=searchString;
cExperiment.pixelSize=pixelSize;
cExperiment.image_rotation=image_rotation;
cExperiment.timepointsToLoad=timepointsToLoad;
traps_present = [];
%% Load timelapses
for i=1:length(positionsToLoad)
    currentPos=positionsToLoad(i);
    cExperiment.cTimelapse=timelapseTraps([cExperiment.rootFolder filesep cExperiment.dirs{currentPos}]);
    cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.magnification,cExperiment.image_rotation,cExperiment.trapsPresent, cExperiment.timepointsToLoad);
    cExperiment.trapsPresent=cExperiment.cTimelapse.trapsPresent;
    cExperiment.magnification=cExperiment.cTimelapse.magnification;
    cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
    cExperiment.searchString=cExperiment.cTimelapse.channelNames;
    %cExperiment.timepointsToLoad=length(cExperiment.cTimelapse.cTimepoint);
    traps_present = cExperiment.cTimelapse.trapsPresent;
    cExperiment.timepointsToProcess = cExperiment.cTimelapse.timepointsToProcess;

    cExperiment.saveTimelapseExperiment(currentPos);
end
