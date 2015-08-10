function KeepKey_Release_cb(GUI,property,src,event)
%KeepKey_Press_cb(GUI,src,event)
%   Call back for the key release function. removes any value from the
%   KeyPressed property of the GUI.

% can be added to a GUI by adding the line:

% set([GUI figure],'WindowKeyReleaseFcn',@(src,event)KeepKey_Release_cb([GUI object],[property name],src,event));

% to the instantiator.

% [GUI figure] is the figure in which the GUI is displayed
% [property name] is the name of the property to set to [] when the key is
% released

% WARNING!!!!
% key release will only trigger if you release the key while that figure is
% in the main view. That meanse that if you hold down a key, do something
% which opens a new window, then release the key, the property given will
% not be reset on the original GUI. This means you have to reset it
% manually during whatever action opens the new figure. Sorry - seems an
% unavoidable matlab problem.

GUI.(property) = [];

end

