function compileData(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.compileCellInformation(posVals);
