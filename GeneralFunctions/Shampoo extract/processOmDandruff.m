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