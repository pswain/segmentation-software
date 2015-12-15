function loadCellVision(cCellVisionGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created cCellVision model used to segmented the loaded timelapses') ;
load(fullfile(PathName,FileName),'cCellVision');
cCellVisionGUI.cCellVision=cCellVision;
