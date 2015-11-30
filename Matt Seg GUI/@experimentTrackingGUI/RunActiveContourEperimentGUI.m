function RunActiveContourEperimentGUI(cExpGUI)
%RunActiveContourEperimentGUI(cExpGUI) Callback for the button to run the
%active contour methods on the experimentTracking Object.

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.RunActiveContourExperimentTracking(cExpGUI.cExperiment.cCellVision,posVals);

end

