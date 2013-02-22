function segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment)

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

for i=1:length(positionsToSegment)
    currentPos=positionsToSegment(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}]);
    cTrapDisplayProcessing(cTimelapse,cCellVision)
    
    cExperiment.posSegmented(currentPos)=1;
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    save([cExperiment.rootFolder '/' cExperiment.dirs{currentPos}],'cTimelapse');
    clear cTimelapse;
end
