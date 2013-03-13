function identifyCells(cTrapsGUI)

answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cTrapsGUI.cCellVision.twoStageThresh)});
cTrapsGUI.cCellVision.twoStageThresh=str2double(answer{1});
cTrapDisplayProcessing(cTrapsGUI.cTimelapse,cTrapsGUI.cCellVision);
