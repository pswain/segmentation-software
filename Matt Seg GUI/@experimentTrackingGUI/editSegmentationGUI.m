function editSegmentationGUI(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.editSegmentation(posVals,[],[],cExpGUI.channel);
