function identifyCells(cTrapsGUI)

answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cTrapsGUI.cCellVision.twoStageThresh)});
cTrapsGUI.cCellVision.twoStageThresh=str2double(answer{1});

answer = inputdlg('Track traps again?','TrackAgain',1,{'0'});
trackTrapsOverwrite=str2double(answer{1})>0;

if trackTrapsOverwrite
    cTrapsGUI.cTimelapse.trackTrapsThroughTime(cTrapsGUI.cCellVision);
end

cTrapDisplayProcessing(cTrapsGUI.cTimelapse,cTrapsGUI.cCellVision);
