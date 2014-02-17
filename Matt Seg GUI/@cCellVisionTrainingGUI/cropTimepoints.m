function cropTimepoints(cCellVisionGUI)

answer=inputdlg('How many timepoints would you like?');
numTimepoints=str2double(answer{1});
randTimepoints=randperm(length(cCellVisionGUI.cTimelapse.cTimepoint));
randTimepoints=randTimepoints(1:numTimepoints);
TimepointToRemove = setdiff(1:length(cCellVisionGUI.cTimelapse.cTimepoint),randTimepoints);
cCellVisionGUI.cTimelapse.cTimepoint(TimepointToRemove)=[];
cCellVisionGUI.cTimelapse.timepointsProcessed(TimepointToRemove)=[];