function loadSavedTimelapse(cCellVisionGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously create TimelapseTraps variable') ;
load(fullfile(PathName,FileName),'cTimelapse');
cCellVisionGUI.cTimelapse=cTimelapse;
cCellVisionGUI.cCellVision.pixelSize=cCellVisionGUI.cTimelapse.pixelSize;
cCellVisionGUI.cCellVision.magnification=cCellVisionGUI.cTimelapse.magnification;

set(cCellVisionGUI.setPixelSizeMenu,'String',num2str(cCellVisionGUI.cTimelapse.pixelSize));

for i=1:length(cTimelapse.cTimepoint)
    cCellVisionGUI.cTimelapse.cTimepoint(i).magnification=cCellVisionGUI.cTimelapse.magnification;
    cCellVisionGUI.cTimelapse.cTimepoint(i).pixelSize=cCellVisionGUI.cTimelapse.pixelSize;
    cCellVisionGUI.cTimelapse.cTimepoint(i).image_rotation=cCellVisionGUI.cTimelapse.image_rotation;
end
