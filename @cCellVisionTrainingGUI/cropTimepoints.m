function cropTimepoints(cCellVisionGUI)

answer=inputdlg('How many timepoints would you like?')
numTimepoints=str2double(answer{1});
randTimepoints=[1 (ceil(rand(1,numTimepoints)*length(cCellVisionGUI.cTimelapse.cTimepoint)))];
randTimepoints=unique(randTimepoints);
cCellVisionGUI.cTimelapse.cTimepoint=cCellVisionGUI.cTimelapse.cTimepoint(randTimepoints);
