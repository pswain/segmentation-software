

t=tic;
cExperiment.trackCells(find(cExperiment.posSegmented),6);

% cExperiment.combineTracklets(find(cExperiment.posSegmented));
%
cTimelapse=cExperiment.returnTimelapse(1);
params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=5;%length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=length(cTimelapse.timepointsProcessed);
params.framesToCheckEnd=1;
cExperiment.selectCellsToPlotAutomatic(find(cExperiment.posTracked),params);
% 
cExperiment.extractCellInformation(find(cExperiment.posTracked),'b');%Use 'max' to include fluorescence info.
cExperiment.compileCellInformationParamsOnly;

%From here
cExperiment.compileCellInformation;
params.motherDurCutoff=180;
params.motherDistCutoff=8;
params.budDownThresh=0;
params.birthRadiusThresh=7;
params.daughterGRateThresh=-1;
cExperiment.extractLineageInfo(find(cExperiment.posTracked),params);


cExperiment.compileLineageInfo;

cExperiment.extractHMMTrainingStates;
%
% cExperiment.trainBirthHMM;

% b=load('C:\Users\mcrane2\OneDrive\timelapses\18-Apr 2014\cExperiment.mat')
% cExperiment.lineageInfo.birthHMM.estTrans=b.cExperiment.lineageInfo.birthHMM.estTrans;
% cExperiment.lineageInfo.birthHMM.estEmis=b.cExperiment.lineageInfo.birthHMM.estEmis;


load('birthHMM_robin.mat')

cExperiment.classifyBirthsHMM(birthHMM);

cExperiment.saveExperiment;
%%
