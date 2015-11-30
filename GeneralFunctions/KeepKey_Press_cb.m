function KeepKey_Press_cb(GUI,property,src,event)
%KeepKey_Press_cb(GUI,src,event)
% 
% GUI       :   a GUI object for which you want to keep a key press
% property  :   property of the GUI object in which to store the character
%               pressed (stored as string)
%
% Call back for the key press function. keeps the string value of the key
% pressed in GUI.(property)
%
% can be added to a GUI by adding the line:
%        set([GUI figure],'WindowKeyPressFcn',@(src,event)KeepKey_Press_cb([GUI object],[property name],src,event));
% to the instantiator.


GUI.(property) = event.Character;


end

