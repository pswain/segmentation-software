function segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment)

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

for i=1:length(positionsToSegment)
    currentPos=positionsToSegment(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cExperiment.cTimelapse=cTimelapse;
    if isempty(cExperiment.cTimelapse.magnification)
        cExperiment.cTimelapse.magnification=60;
    end
    cTrapDisplayProcessing(cTimelapse,cCellVision);
    
    cExperiment.posSegmented(currentPos)=1;
    cExperiment.saveTimelapseExperiment(currentPos);   
    clear cTimelapse;
end
