function reIdentifyCellOutline(cExperiment,cCellVision,positionsToSegment)

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

for i=1:length(positionsToSegment)
    currentPos=positionsToSegment(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cExperiment.currentDir=cExperiment.dirs{currentPos};
    cExperiment.cTimelapse=cTimelapse;
    
    for tpIndex=1:length(cTimelapse.timepointsToProcess)
        tp=cTimelapse.timepointsToProcess(i);
        cTimelapse.identifyCellObjects(cCellVision,tp);
    end
    cExperiment.saveTimelapseExperiment(currentPos);
end