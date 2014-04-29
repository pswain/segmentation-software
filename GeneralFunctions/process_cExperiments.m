
% load('/Users/mcrane2/SkyDrive/timelapses/2

t=tic;
cExperiment.trackCells(find(cExperiment.posSegmented),5);

% cExperiment.combineTracklets(find(cExperiment.posSegmented));
%%
% params.fraction=.8; %fraction of timelapse length that cells must be present or
% params.duration=3;%length(cTimelapse.cTimepoint); %number of frames cells must be present
% params.framesToCheck=length(cTimelapse.cTimepoint);
% params.framesToCheckEnd=1;
cExperiment.selectCellsToPlotAutomatic(find(cExperiment.posTracked));

% cExperiment.extractCellInformation(find(cExperiment.posTracked),'b');
% cExperiment.compileCellInformationParamsOnly;

cExperiment.extractCellInformation(find(cExperiment.posTracked),'max');
cExperiment.compileCellInformation;

params.motherDurCutoff=(.6);
params.motherDistCutoff=2.1;
params.budDownThresh=0;
params.birthRadiusThresh=8;
params.daughterGRateThresh=-1;
cExperiment.extractLineageInfo(find(cExperiment.posTracked),params);


cExperiment.compileLineageInfo;

cExperiment.extractHMMTrainingStates;

cExperiment.trainBirthHMM;

cExperiment.classifyBirthsHMM;

cExperiment.correctSkippedFramesInf

filtParams.num=24;
filtParams.std=12;
filtParams.type='Normal';

cExperiment.extractFitness(params.motherDurCutoff,filtParams);

totalTime=toc(t)