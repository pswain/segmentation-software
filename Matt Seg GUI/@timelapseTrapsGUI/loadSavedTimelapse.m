function loadSavedTimelapse(cTrapsGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously create TimelapseTraps variable') ;
load(fullfile(PathName,FileName),'cTimelapse');
cTrapsGUI.cTimelapse=cTimelapse;

set(cTrapsGUI.selectChannelButton,'String',cTimelapse.channelNames,'Value',1);

if ~isempty(cTimelapse.ActiveContourObject)
    cTrapsGUI.ActiveContourButtonState = 2;
end
