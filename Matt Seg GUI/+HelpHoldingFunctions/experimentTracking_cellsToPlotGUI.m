function [help_string ] = experimentTracking_cellsToPlotGUI()
%
% When you are happy with your cells selection, close the GUI. The
% result will be saved and the next position opened for editing.

help_string = help('cTrapDisplayPlot');
help_string = help_string(1:(end-42)); % cut of last line.
help_string = cat(2,help_string,sprintf('\n\n'),help('HelpHoldingFunctions.experimentTracking_cellsToPlotGUI'));

end

