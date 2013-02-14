function loadCellVision(cTrapsGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of saved CellVision Model') ;

load(fullfile(PathName,FileName),'cCellVision');

cTrapsGUI.cCellVision=cCellVision;

