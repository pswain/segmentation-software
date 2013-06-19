function identifyCells(cExpGUI)

if ~isempty(cExpGUI.cExperiment.cellVisionThresh)
    cExpGUI.cCellVision.twoStageThresh=cExpGUI.cExperiment.cellVisionThresh;
end
answer = inputdlg('Enter twoStage Threshold','TwoStageTreshold',1,{num2str(cExpGUI.cCellVision.twoStageThresh)});
cExpGUI.cCellVision.twoStageThresh=str2double(answer{1});
cExpGUI.cExperiment.cellVisionThresh=cExpGUI.cCellVision.twoStageThresh;


if isempty(cExpGUI.cExperiment.trackTrapsOverwrite)
    cExpGUI.cExperiment.trackTrapsOverwrite=0;
end

answer = inputdlg('Track traps again?','TwoStageTreshold',1,{num2str(cExpGUI.cExperiment.trackTrapsOverwrite)});
cExpGUI.cExperiment.trackTrapsOverwrite=str2double(answer{1})>0;

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
