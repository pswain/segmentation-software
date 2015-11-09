function editSegmentationGUI(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.editSegmentation(cExpGUI.cExperiment.cCellVision,posVals,[],[],cExpGUI.channel);
