function identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify)


if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cTrapSelectDisplay(cTimelapse,cCellVision);
    
    uiwait();
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
end
