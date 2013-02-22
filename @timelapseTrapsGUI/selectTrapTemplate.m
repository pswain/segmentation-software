function selectTrapTemplate(cCellVisionGUI)

cCellVisionGUI.cCellVision.selectTrapTemplate(cCellVisionGUI.cTimelapse)
uiwait()
% Identify the trap outline
cCellVisionGUI.cCellVision.identifyTrapOutline();