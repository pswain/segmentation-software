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




%Call the cExperiment method to extract the budding information - populates
%cExperiment.lineageInfo
cExpGUI.cExperiment.extractBirthsInfo(params);





cExpGUI.cExperiment.extractLineageInfo(find(cExpGUI.cExperiment.posTracked),params);


cExpGUI.cExperiment.compileLineageInfo;

cExpGUI.cExperiment.extractHMMTrainingStates;
%
% cExperiment.trainBirthHMM;

% b=load('C:\Users\mcrane2\OneDrive\timelapses\18-Apr 2014\cExperiment.mat')
% cExperiment.lineageInfo.birthHMM.estTrans=b.cExperiment.lineageInfo.birthHMM.estTrans;
% cExperiment.lineageInfo.birthHMM.estEmis=b.cExperiment.lineageInfo.birthHMM.estEmis;


load('birthHMM_robin.mat')

cExpGUI.cExperiment.classifyBirthsHMM(birthHMM);

%Compile the data into other useful forms for plotting. The function
%compileBirthsForPlot is in the births plotting folder in General Functions
%and is based on an old function called extractDandruffData
cExpGUI.cExperiment.lineageInfo.dataForPlot=compileBirthsForPlot(cExpGUI.cExperiment);

end
