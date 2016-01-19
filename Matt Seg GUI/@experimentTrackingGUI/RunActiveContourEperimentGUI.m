function RunActiveContourEperimentGUI(cExpGUI)
%RunActiveContourEperimentGUI(cExpGUI) Callback for the button to run the
%active contour methods on the experimentTracking Object.

posVals=get(cExpGUI.posList,'Value');

% picked these inputs to minimise confusion. Assumes people are doing the
% active contour after finding the centres and traps by Matt's method.
%RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged,CellsToUse)
cExpGUI.cExperiment.RunActiveContourExperimentTracking(cExpGUI.cExperiment.cCellVision,posVals,[],[],true,2,false);




end

