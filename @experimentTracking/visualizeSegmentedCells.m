function visualizeSegmentedCells(cExperiment,cCellVision,positionsToShow)


if nargin<3
    positionsToShow=1:cExperiment.lastSegmented;
end
    
%% Load timelapses
for i=1:length(positionsToShow)
    currentPos=positionsToShow(i);
    
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}]);
    cTrapDisplay(cTimelapse,cCellVision)
    input('Hit Enter when done with this position');
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}],'cTimelapse');

end
