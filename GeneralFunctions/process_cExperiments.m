
% load('/Users/mcrane2/SkyDrive/timelapses/2

t=tic;
cExperiment.trackCells(find(cExperiment.posSegmented),5);

params.fraction=.1; %fraction of timelapse length that cells must be present or
params.duration=3; %number of frames cells must be present
params.framesToCheck=length(cTimelapse.timepointsProcessed);
params.framesToCheckEnd=1;
params.endThresh=2; %num tp after end of tracklet to look for cells
params.sameThresh=4; %num tp to use to see if cells are the same
params.classThresh=3.8; %classification threshold
cExperiment.combineTracklets(find(cExperiment.posSegmented),params);

params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=3;%length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=length(cTimelapse.cTimepoint);
params.framesToCheckEnd=1;
cExperiment.selectCellsToPlotAutomatic(find(cExperiment.posTracked),params);

cExperiment.extractCellInformation(find(cExperiment.posTracked),'max');

cExperiment.compileCellInformation;
% cExperiment.compileCellInformationParamsOnly; %When selecting 'basic'

params.motherDurCutoff=(.6); %fraction of timelapse the mother is present
params.motherDistCutoff=2.1; %distance from center of dauther to center o mother in radius units. 
params.budDownThresh=0; %
params.birthRadiusThresh=8; %cell has to be smaller than this
params.daughterGRateThresh=-1;
cExperiment.extractLineageInfo(find(cExperiment.posTracked),params);


cExperiment.compileLineageInfo;

cExperiment.extractHMMTrainingStates;

cExperiment.trainBirthHMM;

cExperiment.classifyBirthsHMM;
%%
cExperiment.correctSkippedFramesInf

filtParams.num=24;
filtParams.std=12;
filtParams.type='Normal';

cExperiment.extractFitness(params.motherDurCutoff,filtParams);

totalTime=toc(t)