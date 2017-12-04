function keyPress_cb(cExpGUI,src,event)
% keyPress_cb(cExpGUI,src,event)
%
% Call back for the key press function:
% 
% h             :   (help) doc of experimentTrackingGUI
%



if strcmp(event.Key,'h')
    helpdlg(cExpGUI.gui_help);

end

end

