function displayWholeTimelapse(cExpGUI)
% executes the cTimelapseDisplay timelapse viewing GUI for the first
% position of those selected in the cExpGUI. Sets the channel viewed to be
% that of the cExperiment.

pos=get(cExpGUI.posList,'Value');
pos=pos(1);
cTimelapse=cExpGUI.cExperiment.returnTimelapse(pos);
cExpGUI.currentGUI=cTimelapseDisplay(cTimelapse);
cExpGUI.currentGUI.channel=cExpGUI.channel;
cExpGUI.currentGUI.slider_cb();

