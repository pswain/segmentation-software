function extractBirths(cExpGUI)
%Callback for the extract births button in the cExperimentTrackng GUI.
%Runs code to define the mothers cells and detect their budding events.

%Cells must be segmented, tracked, and selected before this is run. Use
%autoselect with a broad filter (eg cell present for 5 timepoints) to make
%sure you include the daughter cells.

%Define params here or through a dialogue. So far only default params:

params.mStartTime=1;%Only cells present from mStartTime to mEndTime will be included
params.mEndTime=cExpGUI.cExperiment.timepointsToProcess(end);%
params.motherDurCutoff=.4;
params.motherDistCutoff=8;
params.budDownThresh=0;
params.birthRadiusThresh=7;
params.daughterGRateThresh=-1;

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