function identifyCells(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
