function setPixelSize(cCellVisionGUI)


s=get(cCellVisionGUI.setMinRadiusMenu,'String');

cCellVisionGUI.cCellVision.pixelSize=str2double(s);
cCellVisionGUI.cTimelapse.pixelSize=str2double(s);