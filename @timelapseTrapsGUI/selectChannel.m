function selectChannel(cCellVisionGUI)

cCellVisionGUI.channel=get(cCellVisionGUI.selectChannelButton,'Value');
try
    cCellVisionGUI.currentGUI.channel=cCellVisionGUI.channel;
    cCellVisionGUI.currentGUI.slider_cb();
end