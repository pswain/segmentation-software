function cTimelapse=returnTimelapse(cExperiment,timelapseNum)
%cTimelapse=returnTimelapse(cExperiment,timelapseNum)
%
% loads a cTimelapse. timelapseNum should be a single number
% indicating which position to load. Note, timelapseNum indicates an index
% in cExperiment.dirs to load, so depending on the ordering of the
% directories in dirs cExperiment.loadCurrentTimelapse(2) will not
% necessarily load the cTimlapse related to directory pos2, and will in
% general load pos10 - this is due to alphabetic ordering.
%
% the distinction between this method, and
% EXPERIMENTTRACKING.LOADCURRENTTIMELAPSE is that this one does not
% populate the cTimelapse and currentPos fields of the experimentTracking
% object, and as such should just be used to return a cTimelapse.
%
% See also, EXPERIMENTTRACKING.LOADCURRENTTIMELAPSE



load([cExperiment.saveFolder filesep cExperiment.dirs{timelapseNum},'cTimelapse']);
cTimelapse.metadata = cExperiment.metadata;
cTimelapse.metadata.posname = cExperiment.dirs{timelapseNum};

% In either case, once the timelapse is successfully loaded, trigger a
% PositionChanged event to notify experimentLogging
experimentLogging.changePos(cExperiment,timelapseNum,cTimelapse);

% populate these 2 transient properties for when new cells need to be
% detected.
cTimelapse.cCellVision = cExperiment.cCellVision;
cTimelapse.cCellMorph = cExperiment.cCellMorph;
end