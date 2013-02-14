function selectTimelapse(cCellVisionGUI)

cCellVisionGUI.cTimelapse=timelapseTraps();
searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'DIC'});
cCellVisionGUI.cTimelapse.loadTimelapse(searchString);

set(cCellVisionGUI.setPixelSizeMenu,'String',num2str(cCellVisionGUI.cTimelapse.pixelSize));
cCellVisionGUI.cCellVision.pixelSize=cCellVisionGUI.cTimelapse.pixelSize;
