function extractData(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.extractCellInformation(posVals);
