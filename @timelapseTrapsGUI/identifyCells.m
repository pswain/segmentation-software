function identifyCells(cTrapsGUI)

answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cTrapsGUI.cCellVision.twoStageThresh)});
cTrapsGUI.cCellVision.twoStageThresh=str2double(answer{1});

if isempty(cExpGUI.cExperiment.trackTrapsOverwrite)
    cExpGUI.cExperiment.trackTrapsOverwrite=0;
end

answer = inputdlg('Track traps again?','TrackAgain',1,{num2str(cExpGUI.cExperiment.trackTrapsOverwrite)});
trackTrapsOverwrite=str2double(answer{1})>0;

if trackTrapsOverwrite
    cTimelapse.trackTrapsThroughTime(cCellVision,cExperiment.timepointsToProcess);
end

cTrapDisplayProcessing(cTrapsGUI.cTimelapse,cTrapsGUI.cCellVision);
