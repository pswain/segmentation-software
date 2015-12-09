function selectChannel(cExpGUI)

cExpGUI.channel=get(cExpGUI.selectChannelButton,'Value');
try
    cExpGUI.currentGUI.channel=cExpGUI.channel;
    cExpGUI.currentGUI.slider_cb();
end
