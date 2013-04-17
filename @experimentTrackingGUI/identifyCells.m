function identifyCells(cExpGUI)

answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cExpGUI.cCellVision.twoStageThresh)});
cExpGUI.cCellVision.twoStageThresh=str2double(answer{1});

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
