function cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)
%cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)
%
% loads a cTimelapse. Positions to load should be a single number
% indicating which position to load. Note, positionsToLoad indicated index
% in cExperiment.dirs to load, so depending on the ordering of the
% directories in dirs cExperiment.loadCurrentTimelapse(2) will not
% necessarily load the cTimlapse related to directory pos2, and will in
% general load pos10 - his is due to alphabetic ordering.
%
% now just a wrapper for returnTimelapse plus population cTimelapse field
% of cExperiment. Mostly kept for legacy reasons.
%
cTimelapse=cExperiment.returnTimelapse(positionsToLoad);

cExperiment.cTimelapse=cTimelapse;

cExperiment.currentPos = positionsToLoad;
end    