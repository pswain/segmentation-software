function automaticProcessing(cExpGUI)
%Ripped wholesale from functions which work

if ~isempty(cExpGUI.cExperiment.cellVisionThresh)
    cExpGUI.cCellVision.twoStageThresh=cExpGUI.cExperiment.cellVisionThresh;
end


if isempty(cExpGUI.cExperiment.trackTrapsOverwrite)
    cExpGUI.cExperiment.trackTrapsOverwrite=0;
end

posVals=get(cExpGUI.posList,'Value');


params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=30;%length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=5;
params.framesToCheckEnd=1;

if ~isempty(cExpGUI.cExperiment.timepointsToProcess)
    loc=find(cExpGUI.cExperiment.timepointsToProcess);
    params.duration=loc(end); %number of frames cells must be present
    params.framesToCheck=loc(end);
    params.framesToCheckEnd=loc(1);
    
end

%Get info
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
identifyPrompt = inputdlg(prompt,dlg_title,num_lines,def);


prompt = {['Max change in position and radius before a cell is classified as a new cell. A larger number is more lenient, and you will be more likely' ...
    ' to not have interruptions in the tracking for a cell. At the same time though, you will be more likely to identify unrelated cells as the same.' ...
    ' This is especially true for daughters.']};
dlg_title = 'Tracking Threshold';
num_lines = 1;
def = {'30'};
trackPrompt = inputdlg(prompt,dlg_title,num_lines,def);
cellMovementThresh=str2double(trackPrompt{1});

num_lines=1;clear prompt; clear def;
prompt(1) = {'Fraction of whole timelapse a cell must be present'};
prompt(2) = {'OR - number of frames a cell must be present'};
prompt(3) = {'Cell must appear in the first X frames'};
prompt(4) = {'Cell must be present after frame X'};

dlg_title = 'Tracklet params';
def(1) = {num2str(params.fraction)};
def(2) = {num2str(params.duration)};
def(3) = {num2str(params.framesToCheck)};
def(4) = {num2str(params.framesToCheckEnd)};
autoSelectPrompt = inputdlg(prompt,dlg_title,num_lines,def);
params.fraction=str2double(autoSelectPrompt{1});
params.duration=str2double(autoSelectPrompt{2});
params.framesToCheck=str2double(autoSelectPrompt{3});
params.framesToCheckEnd=str2double(autoSelectPrompt{4});

 num_lines=1;
 dlg_title = 'What to extract?';
 prompt = {['All Params using max projection (max), std focus (std), mean focus (mean), using all three measures (all), or basic (basic)' ...
     ' the basic measure only compiles the x, y locations of cells along with the estimated radius so it is much faster, but less informative.']};    def = {'max'};
 extractPrompt = inputdlg(prompt,dlg_title,num_lines,def);
 
 type=extractPrompt{1};

cExpGUI.cCellVision.twoStageThresh=str2double(identifyPrompt{1});
cExpGUI.cExperiment.cellVisionThresh=cExpGUI.cCellVision.twoStageThresh;

cExpGUI.cExperiment.trackTrapsOverwrite=str2double(identifyPrompt{2})>0;

%Identify cells
switch identifyPrompt{3}
    case 'completed'
        cExpGUI.cExperiment.segmentCellsDisplay(cExpGUI.cCellVision,posVals);
    case {'continuous','c','cont'}
        cExpGUI.cExperiment.segmentCellsDisplayContinuous(cExpGUI.cCellVision,posVals);
end
%Track cells
cExpGUI.cExperiment.trackCells(posVals,cellMovementThresh)

%Select Cells
cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals,params);

%Extract Data
cExpGUI.cExperiment.extractCellInformation(posVals,type);
end