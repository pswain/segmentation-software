function clearTrapInfo( cTimelapse )
% clearTrapInfo( cTimelapse ) fairly needless function to clear away the trapInfo completely from
% the cTimelapse and return it to an unblemished state.


[cTimelapse.cTimepoint(:).trapInfo] = deal([]);
[cTimelapse.cTimepoint(:).trapLocations] = deal([]);
cTimelapse.timepointsProcessed = [];
[cTimelapse.cTimepoint(:).trapMaxCell] = deal([]);
[cTimelapse.cTimepoint(:).trapMaxCellUTP] = deal([]);

end

