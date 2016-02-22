function segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment)
% segmentCellsDisplay(cExperiment,cCellVision,positionsToSegment)
%
% optionally tracks each positions in positionsToSegment and then creates a
% cTrapDisplayProcessing GUI which identifies cells at each timepoint in
% turn and displays the results. 
%
% cCellVision          :    and object of the cellVision class which
%                           encodes the SVM for cell centre identification.
%                           Usually taken from the cExperiment object.
% positionsToSegment   :    (optional) array of indices of positions to
%                           segment. Default - 1:length(cExperiment.dirs)
%                           (i.e. all positions)
%
% tracking is done if cExperiment.trackTrapsOverwrite is true. CTimelapse
% is saved after tracking and then again after cell identification.

if nargin<3
    positionsToSegment=1:length(cExperiment.dirs);
end

if cExperiment.trackTrapsOverwrite
    % Start logging protocol
    cExperiment.logger.start_protocol('tracking traps',length(positionsToSegment));
    try
        
    for i=1:length(positionsToSegment)
        currentPos=positionsToSegment(i);
        cTimelapse=cExperiment.loadCurrentTimelapse(currentPos);
        cTimelapse.trackTrapsThroughTime(cCellVision,cExperiment.timepointsToProcess);
        cExperiment.saveTimelapseExperiment(currentPos);

    end
    
    % Finish logging protocol
    cExperiment.logger.complete_protocol;
    catch err
        cExperiment.logger.protocol_error;
        rethrow(err);
    end
end

% Start logging protocol
cExperiment.logger.add_arg('Two stage cell vision threshold',cExperiment.cellVisionThresh);
cExperiment.logger.add_arg('Acquisition status','completed');
cExperiment.logger.start_protocol('identifying cells',length(positionsToSegment));
try

for i=1:length(positionsToSegment)
    currentPos=positionsToSegment(i);
    cTimelapse=cExperiment.loadCurrentTimelapse(currentPos);
    
    b=[cTimelapse.cTimepoint.trapLocations];
    if ~isempty(b) || ~cTimelapse.trapsPresent
        cTrapDisplayProcessing(cTimelapse,cCellVision,cTimelapse.timepointsToProcess,[],[],sprintf('position %d :', currentPos));
    end
    
    cExperiment.posSegmented(currentPos)=1;
    cExperiment.saveTimelapseExperiment(currentPos);
    clear cTimelapse;
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end
