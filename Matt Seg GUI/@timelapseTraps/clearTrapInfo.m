function clearTrapInfo( cTimelapse )
% clearTrapInfo( cTimelapse ) 
%
%fairly needless function to clear away the trapInfo completely from
% the cTimelapse and return it to an unblemished state.

trapInfoTemplate = cTimelapse.trapInfoTemplate;
trapInfoTemplate.cell = cTimelapse.cellInfoTemplate;

[cTimelapse.cTimepoint(:).trapInfo] = deal(trapInfoTemplate);
[cTimelapse.cTimepoint(:).trapLocations] = deal([]);
cTimelapse.timepointsProcessed = false(size(cTimelapse.timepointsToProcess));
[cTimelapse.cTimepoint(:).trapMaxCell] = deal([]);
[cTimelapse.cTimepoint(:).trapMaxCellUTP] = deal([]);

end

