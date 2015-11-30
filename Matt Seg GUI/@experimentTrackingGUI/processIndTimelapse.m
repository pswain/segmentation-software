function processIndTimelapse(cExpGUI)


pos=get(cExpGUI.posList,'Value');
pos=pos(1);
cTimelapse=cExpGUI.cExperiment.returnTimelapse(pos);
cExpGUI.currentGUI=timelapseTrapsGUI(cTimelapse,cExpGUI.cExperiment.cCellVision);
cExpGUI.currentGUI.channel=cExpGUI.channel;

