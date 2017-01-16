function help_string = trap_select_gui_help()
% This the the cTrapSelect GUI. A GUI used for identifying the traps in 
% the positions selected. These will be the traps used throughout the
% processing, and will be the only areas in which cells are detected.
%
% The GUI first automatically detects traps by cross correlation of the
% image from the position at the first timepoint to be processed (i.e.
% declared in set time point to process) with the trap image stored in the
% cellVision model.
%
% The user then adds and removes traps by left and right clicks on the
% image respectively (selected traps are shown as a brighter square) and
% the result is stored. 
% Traps should be removed either because they have been wrongly identified
% or because they will not be processed well (i.e. if they have a lot of
% junk, a strange shape or a somethink like a fixed microscope oil bubble).
%
%
% Red boxes are also shown. These are ExclusionsZones: areas in which traps
% are not automatically identified because the software deems that these
% will drift out of the field of over the course of the timealapse and
% therefore be poorly processed. Add traps here at your own risk.
%
% When you are satisfied, close the figure window. The data will be stored,
% and the same GUI for the next position opened. If you wish to stop, press
% Ctrl-C.
%


help_string = help('HelpHoldingFunctions.trap_select_gui_help');
end