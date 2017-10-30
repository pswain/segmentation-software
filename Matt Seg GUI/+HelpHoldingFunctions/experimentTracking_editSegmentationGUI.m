function [help_string ] = experimentTracking_editSegmentationGUI( )
%
% When you are happy with your editing, close the GUI. The
% result will be saved and the next position opened for editing.

help_string = help('cTrapDisplay');
help_string = help_string(1:(end-37)); % cut of last line.
help_string = cat(2,help_string,sprintf('\n\n'),help('HelpHoldingFunctions.experimentTracking_editSegmentationGUI'));

end

