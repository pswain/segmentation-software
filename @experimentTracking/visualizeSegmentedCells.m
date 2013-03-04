function visualizeSegmentedCells(cExperiment,cCellVision,positionsToShow)


if nargin<3
    positionsToShow=1:cExperiment.lastSegmented;
end

%% Load timelapses
for i=1:length(positionsToShow)
    currentPos=positionsToShow(i);
    
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cTrapDisplay(cTimelapse,cCellVision)
    uiwait();
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
    
end
