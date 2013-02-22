function identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify)


if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}]);
    cTrapSelectDisplay(cTimelapse,cCellVision);
    
    input('Hit Enter when done with this position');
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}],'cTimelapse');
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
end
