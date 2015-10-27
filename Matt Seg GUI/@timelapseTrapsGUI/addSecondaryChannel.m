function addSecondaryChannel(cCellVisionGUI)

searchString = inputdlg('Enter the string to search for the secondary (fluorescent) channel images','SearchString',1,{'GFP'});
cCellVisionGUI.cTimelapse.addSecondaryTimelapseChannel(searchString);
set(cCellVisionGUI.selectChannelButton,'String',cCellVisionGUI.cTimelapse.channelNames,'Value',1);
