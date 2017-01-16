function trackTrapsInTime(cExperiment,positionToTrack,first_timepoint,last_timepoint)
% function trackTrapsInTime(cExperiment,positionToTrack,first_timepoint,last_timepoint)
%
% tracks the traps in time from first_timepoint to last_timepoint. If traps
% are present, requires that they have been selected. 
% If there are no traps it populates the trapInfo and trapLocations fields
% of cTimelapse.cTimepoint(:) as though there were one large trap of size
% cTimelapse.imSize.

if nargin<2 || isempty(positionToTrack)
    positionToTrack = 1:numel(cExperiment.dirs);
end

if nargin<3 || isempty(first_timepoint)
    first_timepoint = min(cExperiment.timepointsToProcess);
end

if nargin<4 || isempty(last_timepoint)
    last_timepoint = max(cExperiment.timepointsToProcess);
end

for posi = 1:numel(positionToTrack)
    pos = positionToTrack(posi);
    cExperiment.loadCurrentTimelapse(pos);
    cExperiment.cTimelapse.trackTrapsThroughTime(first_timepoint:last_timepoint);
    cExperiment.saveTimelapseExperiment;
    
end
end