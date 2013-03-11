function loadCellVision(cExpGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of saved CellVision Model') ;

load(fullfile(PathName,FileName),'cCellVision');

cExpGUI.cCellVision=cCellVision;

