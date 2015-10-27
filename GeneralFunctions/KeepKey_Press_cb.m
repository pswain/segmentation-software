function KeepKey_Press_cb(GUI,property,src,event)
%KeepKey_Press_cb(GUI,src,event)
%   Call back for the key press function. keeps the value of the key
%   pressed in the KeyPressed property of the GUI

% can be added to a GUI by adding the line:

% set([GUI figure],'WindowKeyPressFcn',@(src,event)KeepKey_Press_cb([GUI object],[property name],src,event));

% to the instantiator.

% [GUI figure] is the figure in which the GUI is displayed
% [property name] is the name of the property to set to the value of
% 'character'
% 

GUI.(property) = event.Character;


end

