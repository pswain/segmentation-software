function loadTimelapsePositions(cExperiment,searchString,positionsToLoad,magnification,image_rotation,timepointsToLoad)

if nargin<3 || strcmp(positionsToLoad,'all')
    positionsToLoad=1:length(cExperiment.dirs);
end
    
if nargin<4
    magnification=[];
end

if nargin<5
    image_rotation=[];
end

if nargin<6
    timepointsToLoad=[];
end

cExperiment.searchString=searchString;
%% Load timelapses
for i=1:length(positionsToLoad)
    currentPos=positionsToLoad(i);
    cExperiment.cTimelapse=timelapseTraps([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}]);
    cExperiment.cTimelapse.loadTimelapse(searchString,magnification,image_rotation,timepointsToLoad);
    cTimelapse=cExperiment.cTimelapse;
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}],'cTimelapse');
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
end
