function cropTimepoints(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.cropTimepoints(posVals);
