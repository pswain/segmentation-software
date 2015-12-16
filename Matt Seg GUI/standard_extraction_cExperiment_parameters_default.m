%% parameter function for standard_extraction_cExperiment_preprocessing

params = struct;

% combine tracklets parameters:
% used for combining tracks that seem to be the same cell but have been
% tracked as two different cells.
paramsCombineTracklet.fraction=.1; %fraction of timelapse length that cells must be present or
paramsCombineTracklet.duration=3; %number of frames cells must be present
paramsCombineTracklet.framesToCheck=(max(cExperiment.timepointsToProcess));
paramsCombineTracklet.framesToCheckEnd=1;
paramsCombineTracklet.endThresh=2; %num tp after end of tracklet to look for cells
paramsCombineTracklet.sameThresh=4; %num tp to use to see if cells are the same
paramsCombineTracklet.classThresh=3.8; %classification threshold

params.paramsCombineTracklet = paramsCombineTracklet;

% parameters for automatic cell selection
cTimelapse=cExperiment.returnTimelapse(poses(1));
paramsCellSelect.fraction=.8; %fraction of timelapse length that cells must be present or
paramsCellSelect.duration=4;  %length(cTimelapse.cTimepoint); %number of frames cells must be present
paramsCellSelect.framesToCheck=length(cTimelapse.timepointsProcessed); % time before which a cell must arrive to be considered.
paramsCellSelect.framesToCheckEnd=1; %timepoint after which a cell must arrive for it to be considered a cells.
paramsCellSelect.maximumNumberOfCells = Inf; %maximum number of cells to extract

params.paramsCellSelect = paramsCellSelect;

% parameters for lineage info.
% need to fill in details of what they are.
paramsLineage = paramsCellSelect;
paramsLineage.motherDurCutoff=paramsLineage.framesToCheck/4; 
paramsLineage.motherDistCutoff=8;
paramsLineage.budDownThresh=0;
paramsLineage.birthRadiusThresh=7;
paramsLineage.daughterGRateThresh=-1;

params.paramsLineage = paramsLineage;

% tracking

params.trackingDistance = 5; % threshold of distance between cells at one timpoint and the next. Higher implies more lenient tracking.

