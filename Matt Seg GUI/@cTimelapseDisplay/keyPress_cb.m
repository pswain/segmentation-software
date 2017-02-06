function keyPress_cb(cDisplay,src,event)
% keyPress_cb(cDisplay,src,event)
%
% Call back for the key press function:
% 
% downarrow     :   move the channel displayed down 1
% uparrow       :   move the channel displayed up 1
% h             :   (help) doc of cTimelapseDisplay
%
% in all other cases the key press is just stored like the general key
% press GUI


if strcmp(event.Key,'downarrow')
    new_channel = cDisplay.channel - 1;  
    if new_channel ==0
        new_channel = length(cDisplay.cTimelapse.channelNames);
    end
    cDisplay.channel = new_channel;
    cDisplay.slider_cb;
elseif strcmp(event.Key,'uparrow')
    new_channel = cDisplay.channel + 1;  
    if new_channel >length(cDisplay.cTimelapse.channelNames);
        new_channel = 1;
    end
    cDisplay.channel = new_channel;
    cDisplay.slider_cb;
elseif strcmp(event.Key,'h')
    helpdlg(cDisplay.gui_help);
else
    cDisplay.keyPressed = event.Character;
end


end

