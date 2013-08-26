function cropTraps(cCellVisionGUI)

answer=inputdlg('How many traps would you like?')
numTraps=str2double(answer{1});

for i=1:length(cCellVisionGUI.cTimelapse.cTimepoint)
    cCellVisionGUI.cTimelapse.cTimepoint(i).trapInfo=cCellVisionGUI.cTimelapse.cTimepoint(i).trapInfo(1:numTraps);
    cCellVisionGUI.cTimelapse.cTimepoint(i).trapLocations=cCellVisionGUI.cTimelapse.cTimepoint(i).trapLocations(1:numTraps);
end
% 
% 
% randTimepoints=[1 (ceil(rand(1,numTimepoints)*length(cCellVisionGUI.cTimelapse.cTimepoint)))];
% randTimepoints=unique(randTimepoints);
% cCellVisionGUI.cTimelapse.cTimepoint=cCellVisionGUI.cTimelapse.cTimepoint(randTimepoints);
