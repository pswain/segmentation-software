function editProcessTimelapse(cCellVisionGUI)

cCellVisionGUI.currentGUI=cTrapDisplay(cCellVisionGUI.cTimelapse,cCellVisionGUI.cCellVision);
cCellVisionGUI.currentGUI.channel=cCellVisionGUI.channel;
cCellVisionGUI.currentGUI.slider_cb();

