function segmentCellsDisplayContinuous(cExperiment,cCellVision,positionsToSegment)

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

finishedSeg=false;
while (~finishedSeg)
    newTP=false;
    for i=1:length(positionsToSegment)
        currentPos=positionsToSegment(i);
        load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
        cExperiment.currentDir=cExperiment.dirs{currentPos};
        tempy=cTimelapse.addTimepoints;
        newTP=length(cTimelapse.timepointsToProcess)>sum(cTimelapse.timepointsProcessed);
        newTP=tempy|newTP;
        cExperiment.cTimelapse=cTimelapse;
        if cExperiment.trackTrapsOverwrite & newTP
            tp=1:length(cExperiment.cTimelapse.cTimepoint);
%             tp(cExperiment.cTimelapse.timepointsProcessed(1:end-5)>0)=[];
            cTimelapse.trackTrapsThroughTime(cCellVision,tp);
            
            if isempty(cExperiment.cTimelapse.magnification)
                cExperiment.cTimelapse.magnification=60;
            end
            cExperiment.cTimelapse.timepointsToProcess=tp;
            tp=1:length(cExperiment.cTimelapse.cTimepoint);
            tp(cExperiment.cTimelapse.timepointsProcessed>0)=[];
            cTrapDisplayProcessing(cTimelapse,cCellVision,tp);
            cExperiment.posSegmented(currentPos)=1;
            cExperiment.cTimelapse=cTimelapse;
            cExperiment.saveTimelapseExperiment(currentPos);
        end
    end
    if ~newTP
        pause(30);
    end
end

