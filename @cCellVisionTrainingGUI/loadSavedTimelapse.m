function loadSavedTimelapse(cCellVisionGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously create TimelapseTraps variable') ;
load(fullfile(PathName,FileName),'cTimelapse');
cCellVisionGUI.cTimelapse=cTimelapse;
cCellVisionGUI.cCellVision.pixelSize=cCellVisionGUI.cTimelapse.pixelSize;
set(cCellVisionGUI.setPixelSizeMenu,'String',num2str(cCellVisionGUI.cTimelapse.pixelSize));
