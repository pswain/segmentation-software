function segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment)

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

if cExperiment.trackTrapsOverwrite
    for i=1:length(positionsToSegment)
        currentPos=positionsToSegment(i);
        load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
        cExperiment.currentDir=cExperiment.dirs{currentPos};
        cExperiment.cTimelapse=cTimelapse;
        cTimelapse.trackTrapsThroughTime(cCellVision,cExperiment.timepointsToProcess);
        cExperiment.saveTimelapseExperiment(currentPos);

    end
end


for i=1:length(positionsToSegment)
    currentPos=positionsToSegment(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cExperiment.currentDir=cExperiment.dirs{currentPos};
    cExperiment.cTimelapse=cTimelapse;
    if isempty(cExperiment.cTimelapse.magnification)
        cExperiment.cTimelapse.magnification=60;
    end
    
    b=[cTimelapse.cTimepoint.trapLocations];
    if ~isempty(b) || ~cTimelapse.trapsPresent
        cTrapDisplayProcessing(cTimelapse,cCellVision,cTimelapse.timepointsToProcess,[],[],sprintf('position %d :', currentPos));
    end
    
    cExperiment.posSegmented(currentPos)=1;
    cExperiment.saveTimelapseExperiment(currentPos);
    clear cTimelapse;
end
