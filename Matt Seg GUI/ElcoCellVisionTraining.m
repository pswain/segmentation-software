%% Elco's c cCellVision training script

%% test on old DOA1 training set
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1ainingTimelapse.mat')
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1gfp_SCGlc_00/CellTrainingTimelapse.mat')
cTimelapse.timelapseDir = [];

%% generate training set

cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage=40000; %set to 750 ish for traps
step_size=1;

cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,@(CSVM,image) createImFilterSetNoTrap(CSVM,image));


%% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2
cCellVision.trainingParams.gamma=1
%%
cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
maxTP = 30;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); % set step size so never using more than 30 timepoints
cCellVision.runGridSearchLinear(step_size,cmd);
%%
maxTP = 1000;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
cCellVision.trainingParams.cost=1;
cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];
tic
cCellVision.trainSVMLinear(step_size,cmd);toc

%%

maxTP = 200;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
cCellVision.generateTrainingSet2Stage(cTimelapse,step_size);
%%
maxTP = 30;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
cCellVision.runGridSearch(step_size);

%%
maxTP = 100;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
cmd = ['-t 2 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost),' -g ',num2str(cCellVision.trainingParams.gamma)];
tic
cCellVision.trainSVM(step_size,cmd);toc



%%%%%%%%%%%%%%%%%%  TESTS   %%%%%%%%%%%%%%%%%%%%%%%%%%

%% test function handles thing
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage=0;
step_size=1;
cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,'Reduced');
 A = cCellVision.trainingData.features;
 B = cCellVision.trainingData.class;
 
cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,@(CSVM,image) createImFilterSetCellTrap_Reduced(CSVM,image));
if any(A(:)~= cCellVision.trainingData.features(:)) || any(B(:) ~= cCellVision.trainingData.class(:))
    fprintf('\n problem with function handle type operation \n')
end



