function setCellVisionType(cCellVisionGUI)

cellVisionType=get(cCellVisionGUI.setCellVisionTypeMenu,'Value');

switch cellVisionType
    case 1
        cCellVisionGUI.cCellVision.method='linear';
    case 2
        cCellVisionGUI.cCellVision.method='kernel';
    case 3
        cCellVisionGUI.cCellVision.method='twostage';
end