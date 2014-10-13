%% Elco's c cCellVision training script

%% test on old DOA1 training set
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1ainingTimelapse.mat')
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1gfp_SCGlc_00/CellTrainingTimelapse.mat')
cTimelapse.timelapseDir = [];

%% plate cCellVision
load('~/Documents/microscope_files_swain_microscope/microscope characterisation/SuperTrainingTimelapse.mat')
load('~/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellVision-plates-zstacks(for_trainin).mat')

%% setsegmentation method

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
tic;B = SegMethod(cCellVision,A);toc;
gui.stack = reshape(B,512,512,[]);
gui.LaunchGUI;



%% generate training set

cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage=5000; %set to 750 ish for traps
step_size=15;

debugging = true; %set to false to not get debug outputs
%debugging = false;

debug_outputs  =  cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,SegMethod,debugging);

%debug_outputs = { negatives_stack , positive_stack , neg_exclude_stack}


%% show debug outputs

for i=1:length(cTimelapse.cTimepoint)
    image_to_show = cTimelapse.returnSegmenationTrapsStack(1,i);
    image_to_show = image_to_show{1}(:,:,2);
    image_to_show = repmat(image_to_show,[1,1,3]);
    image_to_show = image_to_show.*(1 + ...
        cat(3,debug_outputs{1}(:,:,i),debug_outputs{2}(:,:,i),debug_outputs{3}(:,:,i)));
    image_to_show = (image_to_show - min(image_to_show(:)))./(max(image_to_show(:)) - min(image_to_show(:)));
    imshow(image_to_show,[]);
    pause;
end
    

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



