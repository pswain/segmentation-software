function segmentCellsDisplayContinuous(cExperiment,cCellVision,positionsToSegment,expected_final_timepoint)
% segmentCellsDisplayContinuous(cExperiment,cCellVision,positionsToSegment,expected_final_timepoint)
%
% method that allows the continuous segmentation of an experiment while it
% is being acquired.        
% 
% cExperiment               :   object of the experimentTracking class
% cCellVision               :   object of the cellVision class
% positionsToSegment        :   optional. Positions to segment. Defaults to
%                               all the position. in cExperiment.
% expected_final_timepoint  :   optional. If provided, the software will
%                               stop when all the position have this many
%                               timepoints proessed (measured as sum of
%                               cTimelapse.timepointsProcessed). Default to
%                               Inf, in which case it must be stopped with
%                               ctrl C.
%
% Performs tracking and cell identification in a continuous loop that stops
% either when all positions have been processed for
% expected_final_timepoint timepoints or has to be manually exited.
% Decision image caculation will be slightly different at the 'junction'
% timpoints, so that the result will not be exactly the same as that of a
% completely acquired timelapse, but the effect is likely to be minimal.
%
% cExperiment.timepointsToProcess will correspond to the longest timeseries
% found so far. May cause problems in later processing if different
% positions have different number of timepoints

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

if nargin<4 || isempty(expected_final_timepoint)
    expected_final_timepoint = Inf;
end
min_tp = 0;
while min_tp<expected_final_timepoint
    
    % ensures first cTimelapse loaded will replace min_tp.
    min_tp = Inf;
    newTP=false;
    for i=1:length(positionsToSegment)
        currentPos=positionsToSegment(i);
        cTimelapse = cExperiment.loadCurrentTimelapse(currentPos);
        
        % set min_tp to be the smallest timepoint length of all those
        % segmented
        min_tp = min(min_tp,sum(cTimelapse.timepointsProcessed));
        
        tempy=cTimelapse.addTimepoints;
        newTP=length(cTimelapse.timepointsToProcess)>sum(cTimelapse.timepointsProcessed);
        newTP=tempy|newTP;
        if cExperiment.trackTrapsOverwrite & newTP
            max_new_tp = length(cTimelapse.cTimepoint);
            max_old_tracked = find(~cellfun('isempty',{cTimelapse.cTimepoint(:).trapInfo}),1,'first');
            tp=1:max_new_tp;
            %track only over a subset of old timepoint, those already
            %tracked will not have their timepoints changed and are just
            %there to try and ensure consistency in trap positioning.
            %40 is an arbitrary number- high enough that tracking doesn't
            %take ages, low enough that images will not get confused by
            %high drift.
            
            tp_to_track = [1:40:(max_old_tracked) (max_old_tracked+1):max_new_tp];
            cTimelapse.trackTrapsThroughTime(tp_to_track,true);
            

            cTimelapse.timepointsToProcess = tp;
            cExperiment.timepointsToProcess = tp;
            cTimelapse.timepointsProcessed((end+1):max_new_tp) = 0;
            tp(cTimelapse.timepointsProcessed>0) = [];
            cTrapDisplayProcessing(cTimelapse,cCellVision,tp);
            cExperiment.posSegmented(currentPos) = 1;
            cExperiment.cTimelapse = cTimelapse;
            cExperiment.saveTimelapseExperiment(currentPos);
        end
    end
    if ~newTP
        pause(30);
    end
end

