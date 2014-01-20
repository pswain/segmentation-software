function loadTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad)

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

%% Load timelapses
for i=1:length(positionsToLoad)
    currentPos=positionsToLoad(i);
    cExperiment.cTimelapse=timelapseTraps([cExperiment.saveFolder '/' cExperiment.dirs{currentPos}]);
    cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.pixelSize,cExperiment.image_rotation,timepointsToLoad);
    cExperiment.pixelSize=cExperiment.cTimelapse.pixelSize;
    cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
    cExperiment.searchString=cExperiment.cTimelapse.channelNames;

    cTimelapse=cExperiment.cTimelapse;
    save([cExperiment.saveFolder '/'],[cExperiment.dirs{currentPos}, 'cTimelapse']);
    save([cExperiment.saveFolder '/cExperiment'],'cExperiment');
end
