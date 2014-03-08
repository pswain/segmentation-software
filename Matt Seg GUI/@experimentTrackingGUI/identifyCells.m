function identifyCells(cExpGUI)

if ~isempty(cExpGUI.cExperiment.cellVisionThresh)
    cExpGUI.cCellVision.twoStageThresh=cExpGUI.cExperiment.cellVisionThresh;
end
answer = inputdlg('Enter twoStage Threshold (+ is more lenient, - is harsher)','TwoStageTreshold',1,{num2str(cExpGUI.cCellVision.twoStageThresh)});
cExpGUI.cCellVision.twoStageThresh=str2double(answer{1});
cExpGUI.cExperiment.cellVisionThresh=cExpGUI.cCellVision.twoStageThresh;


if isempty(cExpGUI.cExperiment.trackTrapsOverwrite)
    cExpGUI.cExperiment.trackTrapsOverwrite=0;
end

answer = inputdlg(['Track traps again? (This goes through all timelapses and adjusts for any drift or change in the x-y position.' ...
    'If it has been done once, and you were satisfied with the drift correction, you dont need to do it again'],'TwoStageTreshold',1,{num2str(cExpGUI.cExperiment.trackTrapsOverwrite)});
cExpGUI.cExperiment.trackTrapsOverwrite=str2double(answer{1})>0;

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
