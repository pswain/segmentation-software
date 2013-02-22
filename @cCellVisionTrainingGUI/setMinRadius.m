function setMinRadius(cCellVisionGUI)

s=get(cCellVisionGUI.setMinRadiusMenu,'String');
v=get(cCellVisionGUI.setMinRadiusMenu,'Value');

cCellVisionGUI.cCellVision.radiusSmall=str2double(s(v,:));