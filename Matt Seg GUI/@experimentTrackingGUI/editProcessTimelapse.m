function editProcessTimelapse( cExpGUI )
%EDITPROCESSTIMELAPSE Edit the segmented cells
%   Detailed explanation goes here

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.editTimelapse(cExpGUI.cCellVision,posVals);


end

