function identifyCells(cTrapsGUI)

answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cTrapsGUI.cCellVision.twoStageThresh)});
cTrapsGUI.cCellVision.twoStageThresh=str2double(answer{1});

answer = inputdlg('Track traps again?','TrackAgain',1,{0});
trackTrapsOverwrite=str2double(answer{1})>0;

if trackTrapsOverwrite
    cTimelapse.trackTrapsThroughTime(cCellVision,cExperiment.timepointsToProcess);
end

cTrapDisplayProcessing(cTrapsGUI.cTimelapse,cTrapsGUI.cCellVision);
