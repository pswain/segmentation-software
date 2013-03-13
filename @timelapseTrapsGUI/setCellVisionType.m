function setCellVisionType(cCellVisionGUI)

cellVisionType=get(cCellVisionGUI.setCellVisionTypeMenu,'Value');

switch cellVisionType
    case 1
        cCellVisionGUI.cCellVison.method='linear';
    case 2
        cCellVisionGUI.cCellVison.method='kernel';
    case 3
        cCellVisionGUI.cCellVison.type='twostage';
end