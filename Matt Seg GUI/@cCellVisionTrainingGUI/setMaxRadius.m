function setMaxRadius(cCellVisionGUI)

s=get(cCellVisionGUI.setMaxRadiusMenu,'String');
v=get(cCellVisionGUI.setMaxRadiusMenu,'Value');

cCellVisionGUI.cCellVision.radiusLarge=str2double(s(v,:));