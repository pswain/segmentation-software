function setNegTrainingNum(cCellVisionGUI)

s=get(cCellVisionGUI.setNegTrainingNumMenu,'String');
v=get(cCellVisionGUI.setNegTrainingNumMenu,'Value');
cCellVisionGUI.cCellVision.negativeSamplesPerImage=str2double(s(v,:));