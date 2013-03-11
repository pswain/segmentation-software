function useCurrentTrap(cCellVisionGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of cCellVision Model used to create this segmentation') ;
load(fullfile(PathName,FileName),'cCellVision');

cCellVisionGUI.cCellVision.cTrap=cCellVision.cTrap;
