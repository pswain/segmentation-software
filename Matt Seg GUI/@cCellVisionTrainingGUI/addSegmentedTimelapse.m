function addSegmentedTimelapse(cCellVisionGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created TimelapseTraps variable') ;
load(fullfile(PathName,FileName),'cTimelapse');

len=length(cCellVisionGUI.cTimelapse.cTimepoint);
index=1;
for i=1:length(cTimelapse.cTimepoint)
    if ~isempty(cTimelapse.cTimepoint(i).trapInfo)

    cCellVisionGUI.cTimelapse.cTimepoint(index+len).filename=cTimelapse.cTimepoint(i).filename;
    cCellVisionGUI.cTimelapse.cTimepoint(index+len).trapLocations=cTimelapse.cTimepoint(i).trapLocations;
    cCellVisionGUI.cTimelapse.cTimepoint(index+len).trapInfo=cTimelapse.cTimepoint(i).trapInfo;
    cCellVisionGUI.cTimelapse.cTimepoint(index+len).magnification=cTimelapse.magnification;
        cCellVisionGUI.cTimelapse.cTimepoint(index+len).pixelSize=cTimelapse.pixelSize;
    cCellVisionGUI.cTimelapse.cTimepoint(index+len).image_rotation=cTimelapse.image_rotation;

    index=index+1;
    end
end

index


cCellVisionGUI.cCellVision.pixelSize=cCellVisionGUI.cTimelapse.pixelSize;
cCellVisionGUI.cCellVision.magnification=cCellVisionGUI.cTimelapse.magnification;

set(cCellVisionGUI.setPixelSizeMenu,'String',num2str(cCellVisionGUI.cTimelapse.pixelSize));
