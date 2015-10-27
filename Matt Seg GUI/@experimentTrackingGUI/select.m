function select(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.selectCellsToPlot(cExpGUI.cCellVision,posVals);
