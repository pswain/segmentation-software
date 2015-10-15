function timepointsToProcess(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.selectTPToProcess(posVals);
