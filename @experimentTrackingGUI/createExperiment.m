function createExperiment(cExpGUI)

cExpGUI.cExperiment=experimentTracking();
cExpGUI.cExperiment.createTimelapsePositions();
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);