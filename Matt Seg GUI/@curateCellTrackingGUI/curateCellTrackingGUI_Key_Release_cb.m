function curateCellTrackingGUI_Key_Release_cb(GUI,property,src,event)
%curateCellTrackingGUI_Key_Release_cb(GUI,src,event)
% Call back for the key release function. Sets GUI.(property) to [].
%
% GUI       :   GUI object
% property  :   property of GUI to set to [] when a key is released
%
% special for curateCellTracking - ignores release of uparrow,downarrow or
% return.
% 

if ~ismember(event.Key,{'return','uparrow','downarrow'})
    GUI.(property) = [];
end
end

