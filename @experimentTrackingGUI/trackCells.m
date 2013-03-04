function trackCells(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.trackCells(posVals);
