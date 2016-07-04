function curateCellTrackingGUI_KeyPress_cb(TrackingCurator,src,event)
% curateCellTrackingGUI_KeyPress_cb(TrackingCurator,src,event)
%
% Call back for the key press function. Has various key press functions:
% return        :   cycle through colour schemes
% downarrow     :   cycle all entries in TrackingCurator.Channels up one
% uparrow       :   cycle all entries in TrackingCurator.Channels down one
%
% in all other cases the key press is just stored like the general key
% press GUI
%

if strcmp(event.Key,'return')
    %move tracking curator to the next colour scheme in the list
    n = find(strcmp(TrackingCurator.ColourScheme,TrackingCurator.allowedColourSchemes));
    n = mod(n,length(TrackingCurator.allowedColourSchemes))+1;
    TrackingCurator.ColourScheme = TrackingCurator.allowedColourSchemes{n};
    TrackingCurator.UpdateImages;
elseif strcmp(event.Key,'downarrow')
    new_channel = TrackingCurator.Channels - 1;  
    if any(new_channel ==0)
        new_channel(new_channel==0) = length(TrackingCurator.cTimelapse.channelNames);
    end
    TrackingCurator.Channels = new_channel;
    TrackingCurator.DataObtained(:) = false;
     TrackingCurator.UpdateImages;
elseif strcmp(event.Key,'uparrow')
    TrackingCurator.Channels = mod(TrackingCurator.Channels,length(TrackingCurator.cTimelapse.channelNames)) + 1;
    TrackingCurator.DataObtained(:) = false;
    TrackingCurator.UpdateImages;
elseif strcmp(event.Character,TrackingCurator.closeKey)
    close(TrackingCurator.figure)
else
    TrackingCurator.keyPressed = event.Character;
end


end

