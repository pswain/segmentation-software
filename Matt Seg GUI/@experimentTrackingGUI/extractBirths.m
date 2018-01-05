function extractBirths(cExpGUI)
%Callback for the extract births button in the cExperimentTrackng GUI.
%Runs code to define the mothers cells and detect their budding events.

%Cells must be segmented, tracked, and selected before this is run. Use
%autoselect with a broad filter (eg cell present for 5 timepoints) to make
%sure you include the daughter cells.

%Define parameters
num_lines=1;clear prompt; clear def;
prompt(1)={'Starting timepoint (only cells present from this time and up to the end time will be included)'};
prompt(2) = {'End timepoint (only cells present from the start time to this time will be included'};
prompt(3)={'motherDurCutoff'};
prompt(4)={'motherDistCutoff'};
prompt(5)={'budDownThresh'};
prompt(6)={'birthRadiusThresh'};
prompt(7)={'daughterGRateThresh'};

dlg_title = 'Extract births info, define parameters';
def(1) = {'1'};
def(2) = {num2str(cExpGUI.cExperiment.timepointsToProcess(end))};
def(3) = {'.4'};
def(4) = {'8'};
def(5) = {'0'};
def(6) = {'7'};
def(7) = {'-1'};

answer = inputdlg(prompt,dlg_title,num_lines,def);

params.mStartTime=str2double(answer{1});
params.mEndTime=str2double(answer{2});
params.motherDurCutoff=str2double(answer{3});
params.motherDistCutoff=str2double(answer{4});
params.budDownThresh=str2double(answer{5});
params.birthRadiusThresh=str2double(answer{6});
params.daughterGRateThresh=str2double(answer{7});


poses=get(cExpGUI.posList,'Value');

cExperiment = cExpGUI.cExperiment;

% get mother index
for diri=poses
    
    cTimelapse = cExperiment.loadCurrentTimelapse(diri);
    cTimelapse.findMotherIndex;
    cExperiment.cTimelapse = cTimelapse;
    cExperiment.saveTimelapseExperiment(diri,false);

    
end

% mother processing
cExperiment.extractLineageInfo(poses,params);
cExperiment.compileLineageInfo(poses);
cExperiment.extractHMMTrainingStates;
cExperiment.trainBirthHMM;
cExperiment.classifyBirthsHMM;

% save experiment 
cExperiment.saveExperiment;

end
