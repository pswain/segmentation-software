function No_KeyPress_cb(GUI,src,event)
%No_KeyPress_cb(GUI,src,event)
%   Call back for the key press function. Just stops the figure
%   dissappearing and text appearing in the command line and thereby allows
%   mouse click outcome to be conditioned on key down

% can be added to a GUI by adding the line:

% set([GUI figure],'WindowKeyPressFcn',@(src,event)No_KeyPress_cb([GUI object],src,event));

% to the instantiator. (though the inputs are currently unneccssary)

% [GUI figure] is the figure in which the GUI is displayed



end

