function identifyCells(cExpGUI)

if ~isempty(cExpGUI.cExperiment.cellVisionThresh)
    cExpGUI.cCellVision.twoStageThresh=cExpGUI.cExperiment.cellVisionThresh;
end


if isempty(cExpGUI.cExperiment.trackTrapsOverwrite)
    cExpGUI.cExperiment.trackTrapsOverwrite=0;
end

posVals=get(cExpGUI.posList,'Value');


num_lines=1;clear prompt; clear def;
prompt(1)={'Enter twoStage Threshold (+ is more lenient, - is harsher)'};
prompt(2) = {['Track traps again (1=yes, 0=no)? (This goes through all timelapses and adjusts for any drift or change in the x-y position.' ...
    'If it has been done once, and you were satisfied with the drift correction, you dont need to do it again']};
prompt(3) = {['Would you like to segment an experiment as the images are being acquired, or has the acquisition been completed?' ...
    ' (enter completed or continuous). The continuous segmentation must be stopped by a control-c.']};
dlg_title = 'Cell Segmentation';
def(1) = {num2str(cExpGUI.cCellVision.twoStageThresh)};
def(2) = {num2str(cExpGUI.cExperiment.trackTrapsOverwrite)};
def(3) = {'completed'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

cExpGUI.cCellVision.twoStageThresh=str2double(answer{1});
cExpGUI.cExperiment.cellVisionThresh=cExpGUI.cCellVision.twoStageThresh;

cExpGUI.cExperiment.trackTrapsOverwrite=str2double(answer{2})>0;

switch answer{3}
    case 'completed'
        cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
    case {'continuous','c','cont'}
        cExpGUI.cExperiment.segmentCellsDisplayContinuous(cExpGUI.cCellVision,posVals);
end

        