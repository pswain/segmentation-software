function displayWholeTimelapse(cExpGUI)

pos=get(cExpGUI.posList,'Value');
pos=pos(1);
cTimelapse=cExpGUI.cExperiment.returnTimelapse(pos);
cExpGUI.currentGUI=cTimelapseDisplay(cTimelapse);
cExpGUI.currentGUI.channel=cExpGUI.channel;
cExpGUI.currentGUI.slider_cb();

