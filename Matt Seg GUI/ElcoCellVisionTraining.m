%% Elco's c cCellVision training script

%% test on old DOA1 training set
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1ainingTimelapse.mat')
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1gfp_SCGlc_00/CellTrainingTimelapse.mat')
cTimelapse.timelapseDir = [];

%% plate cCellVision
load('~/Documents/microscope_files_swain_microscope/microscope characterisation/SuperTrainingTimelapse.mat')
load('~/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellVision-plates-zstacks(for_trainin).mat')

%% use cExperiment to make a training set - WARNING, generally will load a cCellVision

num_timepoints = 30;

[file,path] = uigetfile('~/Documents/microscope_files_swain_microscope/');
load(fullfile(path,file));

fprintf('\n\n choose a new location in which to save the training cExperiment \n \n');
[NewExpLocation] = uigetdir(path);

OldExpLocation = cExperiment.saveFolder;

DirToUse = 1:length(cExperiment.dirs);
TPtoUse = ones(size(DirToUse));

if length(cExperiment.dirs)>num_timepoints
    
    DirToUse = randperm(length(cExperiment.dirs));
    DirToUse = DirToUse(1:num_timepoints);
    TPtoUse = ones(size(DirToUse));
    
end

if length(cExperiment.dirs)<num_timepoints
    
    TPtoUse = floor(num_timepoints/length(cExperiment.dirs))*ones(size(DirToUse));
    remainder = mod(num_timepoints,length(cExperiment.dirs));
    if remainder>0
        
        assign_remainders = randperm(length(cExperiment.dirs));
        assign_remainders = assign_remainders(1:remainder);
        TPtoUse(assign_remainders) = TPtoUse(assign_remainders)+1; 
        
    end

end

cExperiment.dirs = cExperiment.dirs(DirToUse);

for di = 1:length(cExperiment.dirs)

    load(fullfile(OldExpLocation , [cExperiment.dirs{di},'cTimelapse']),'cTimelapse');
    TPs = randperm(length(cTimelapse.timepointsToProcess));
    TPs = cTimelapse.timepointsToProcess(TPs(1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess))));
    cTimelapse.cTimepoint = cTimelapse.cTimepoint(TPs);
    %cTimelapse.timepointsProcessed = cTimelapse.timepointsProcessed(TPs);
    cTimelapse.timepointsToProcess = 1:min(TPtoUse(di),length(cTimelapse.timepointsToProcess));
    save(fullfile(NewExpLocation , [cExperiment.dirs{di},'cTimelapse']),'cTimelapse')
    
end

cExperiment.saveFolder = NewExpLocation;
cExperiment.cCellVision = cCellVision;
cExperiment.saveExperiment;

%% open a GUI to edit the experiment


expGUI = experimentTrackingGUI;

%% make training timelapse from cExperiment - WARNING, generally will load a cCellVision
%  Needs to already be segmented and curated (can't do it afterwards unless non trap timelapse)

[file,path] = uigetfile('~/Documents/microscope_files_swain_microscope/');
load(fullfile(path,file));


for di = 1:length(cExperiment.dirs)
    
    load(fullfile(cExperiment.saveFolder , [cExperiment.dirs{di},'cTimelapse']),'cTimelapse');
        if di==1
            cTimelapseAll = fuseTimlapses({cTimelapse});
        else
    cTimelapseAll = fuseTimlapses({cTimelapseAll,cTimelapse});
        end
    clear cTimelapse
    
end

cTimelapse = cTimelapseAll;
clear cTimelapseAll

cTimelapseDisplay(cTimelapse)

%%
clear cExperiment currentPos di file path

figure;imshow(OverlapGreyRed(double(cCellVision.cTrap.trap1),cCellVision.cTrap.trapOutline,[],[],true),[]);
%% improve cCellvision trap outline

    which_cell_to_use = 2;

%this file should only have the cCellVision variable

ttacObject.cCellVision = cCellVision;

if which_cell_to_use==1

    TrapIM = double(cCellVision.cTrap.trap1);
else
    TrapIM = double(cCellVision.cTrap.trap2);
end


TrapPixelImage = ACTrapFunctions.make_trap_pixels_from_image(TrapIM);
cCellVision.cTrap.trapOutline = TrapPixelImage;


%% set segmentation method

SegMethod = @(CSVM,image) createImFilterSetNoTrapSlim(CSVM,image);


%% check histrogram of images

figure;
values = {};
bins = {};
for ti = 1:length(cTimelapse.cTimepoint)
    imS = cTimelapse.returnSegmenationTrapsStack(1,ti);
    imS = imS{1};
    title(sprintf('timepoint %d',ti))
    for slicei = 1:size(imS,3)
        im = imS(:,:,slicei);
        im = im - median(im(:));
        im = im/iqr(im(:));
        %im = im/median(im(:));
        if ti==1 
            [values{slicei},bins{slicei}] = hist(im(:),200);
        else
            [valuestemp] = hist(im(:),bins{slicei});
            values{slicei} = cat(1,values{slicei},valuestemp);
        end
    end
    
end

for slicei = 1:size(imS,3)
    
    subplot(size(imS,3),1,slicei)
    plot(bins{slicei},log(values{slicei} +1));

end
%% look at single image from cCellVision

gui = GenericStackViewingGUI;
A =cTimelapse.returnSegmenationTrapsStack(1,1);
A = A{1};
figure(4);imshow(A(:,:,2),[])
gui.stack = A;
gui.LaunchGUI

%%

tic;B = SegMethod(cCellVision,A);toc;
gui.stack = reshape(B,size(A,1),size(A,2),[]);
gui.LaunchGUI;



%% generate training set

cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage=10000; %set to 750 ish for traps 5000 for whole field images
step_size=1;

debugging = false; %set to false to not get debug outputs
%debugging = false;

debug_outputs  =  cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,SegMethod,debugging);

%debug_outputs = { negatives_stack , positive_stack , neg_exclude_stack}


%% show debug outputs

numTraps = size(debug_outputs{1},3);
debugStack = zeros(size(debug_outputs{1},1),size(debug_outputs{1},2),numTraps*3);
nT = 1;
nTr = 1;
nTrT = 1;
while nTrT<=numTraps
    TrapIm = cTimelapse.returnTrapsTimepoint([],nT,1);
    for iT = 1:size(TrapIm,3)
        image_to_show = repmat(double(TrapIm(:,:,iT)),[1,1,3]);
        image_to_show = image_to_show.*(1 + ...
        cat(3,debug_outputs{1}(:,:,nTrT),debug_outputs{2}(:,:,nTrT),debug_outputs{3}(:,:,nTrT)));
        image_to_show = (image_to_show - min(image_to_show(:)))./(max(image_to_show(:)) - min(image_to_show(:)));
        debugStack(:,:,3*nTrT + [-2 -1 0]) = image_to_show;
        nTrT = nTrT + 1;
    end
    fprintf('timepoint nT of some\n')
    nT = nT +1;
    
    
end

gui.stack = debugStack;
gui.type = 'tri-stack';
gui.LaunchGUI;


%% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2
cCellVision.trainingParams.gamma=1
%% parameter grid search
%cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
ws = [sum(cCellVision.trainingData.class)/length(cCellVision.trainingData.class) 1];
ws = round(ws./min(ws,[],2));
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); %sets negative weights to be such that total of negative and positive is hte same
maxTP = 30;
step_size=max(length(cTimelapse.cTimepoint),max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1])); % set step size so never using more than 30 timepoints
cCellVision.runGridSearchLinear(step_size,cmd);
%% linear training
maxTP = 1000;
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); 
%cCellVision.trainingParams.cost=1;
%cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];

cmd=sprintf('-s 1 -w0 %d -w1 %d -c %f'...
    ,ws(1),ws(2),cCellVision.trainingParams.cost); %sets positive and negative weights to be such that total of negative and positive is the same

tic
cCellVision.trainSVMLinear(step_size,cmd);toc

%% open a timelapse to check how good it is

disp = experimentTrackingGUI

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



