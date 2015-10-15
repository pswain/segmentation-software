function curateCellTrackingGUI_KeyPress_cb(TrackingCurator,src,event)
% curateCellTrackingGUI_KeyPress_cb(TrackingCurator,src,event)
%   Call back for the key press function. Just stops the figure dissappearing and text appearing in the command line 

if strcmp(event.Key,'return')
    %move tracking curator to the next colour scheme in the list
    n = find(strcmp(TrackingCurator.ColourScheme,TrackingCurator.allowedColourSchemes));
    n = mod(n,length(TrackingCurator.allowedColourSchemes))+1;
    TrackingCurator.ColourScheme = TrackingCurator.allowedColourSchemes{n};
    TrackingCurator.UpdateImages;
elseif strcmp(event.Key,'downarrow')
    new_channel = TrackingCurator.Channels - 1;  
    if new_channel ==0
        new_channel = length(TrackingCurator.cTimelapse.channelNames);
    end
    TrackingCurator.Channels = new_channel;
    TrackingCurator.DataObtained(:) = false;
     TrackingCurator.UpdateImages;
elseif strcmp(event.Key,'uparrow')
    TrackingCurator.Channels = mod(TrackingCurator.Channels,length(TrackingCurator.cTimelapse.channelNames)) + 1;
    TrackingCurator.DataObtained(:) = false;
    TrackingCurator.UpdateImages;
else
    TrackingCurator.keyPressed = event.Character;
end


end

