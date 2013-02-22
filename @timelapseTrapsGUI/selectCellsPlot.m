function selectCellsPlot(cCellVisionGUI)

cCellVisionGUI.currentGUI=cTrapDisplayPlot(cCellVisionGUI.cTimelapse,cCellVisionGUI.cCellVision);
cCellVisionGUI.currentGUI.channel=cCellVisionGUI.channel;
cCellVisionGUI.currentGUI.slider_cb();
