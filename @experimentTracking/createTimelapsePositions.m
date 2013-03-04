function createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad)


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
%% Load timelapses
for i=1:length(positionsToLoad)
    currentPos=positionsToLoad(i);
    cExperiment.cTimelapse=timelapseTraps([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}]);
    cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.pixelSize,cExperiment.image_rotation,cExperiment.timepointsToLoad);
    cExperiment.pixelSize=cExperiment.cTimelapse.pixelSize;
    cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
    cExperiment.searchString=cExperiment.cTimelapse.channelNames;
    cExperiment.timepointsToLoad=length(cExperiment.cTimelapse.cTimepoint);

    cExperiment.saveTimelapseExperiment(currentPos);
end
