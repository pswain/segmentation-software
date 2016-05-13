function addSecondaryChannel(cExpGUI)

channel_name = addSecondaryChannel(cExpGUI.cExperiment);
set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);