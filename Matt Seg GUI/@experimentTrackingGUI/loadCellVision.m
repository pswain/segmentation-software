function loadCellVision(cExpGUI,FileName,PathName)

if nargin<3
    [FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of saved CellVision Model') ;
end
load(fullfile(PathName,FileName),'cCellVision');

cExpGUI.cCellVision=cCellVision;
cExpGUI.cExperiment.cCellVision=cCellVision;


