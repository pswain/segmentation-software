function select(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.selectCellsToPlot(cExpGUI.cExperiment.cCellVision,posVals,cExpGUI.channel);
