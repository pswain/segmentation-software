function createExperiment(cExpGUI)
% createExperiment(cExpGUI)
% create a new experiment from file location (as oppose to Omero)
cExpGUI.cExperiment=experimentTracking();

% createTimelapsePositions given with explicit arguments so that all
% positions are loaded.
cExpGUI.cExperiment.createTimelapsePositions([],'all');

set(cExpGUI.posList,'Value',1);
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);

set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
cExpGUI.channel = 1;

set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);

if ~cExpGUI.cExperiment.trapsPresent
    set(cExpGUI.selectTrapsToProcessButton,'Enable','off');
else
    set(cExpGUI.selectTrapsToProcessButton,'Enable','on');
end

end
