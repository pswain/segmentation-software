function selectTrapsToProcess(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.identifyTrapsTimelapses(cExpGUI.cExperiment.cCellVision,posVals);
