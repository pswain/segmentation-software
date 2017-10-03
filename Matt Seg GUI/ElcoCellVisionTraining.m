%% Elco's c cCellVision training script

%% test on old DOA1 training set
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1ainingTimelapse.mat')
load('~/Documents/microscope_files_swain_microscope/DOA1/2013_03_24/DOA1gfp_SCGlc_00/CellTrainingTimelapse.mat')
cTimelapse.timelapseDir = [];

%% plate cCellVision
load('~/Documents/microscope_files_swain_microscope/microscope characterisation/SuperTrainingTimelapse.mat')
load('~/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellVision-plates-zstacks(for_trainin).mat')

%% load cExperiment 

[file,path] = uigetfile('~/Documents/microscope_files_swain_microscope_analysis/');
load(fullfile(path,file),'cExperiment');

%% load cCellVision

[file,path] = uigetfile('~/SkyDrive/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellvisionFiles/');
load(fullfile(path,file),'cCellVision');



%% initialise for cExperiment compilation

cExperiment =[];
num_timepoints = 5;

%% select cExperiments you want to add to the gound truth set.
% num_timpoints timepoints will be added from each one.

%a = inputdlg('provide append name');
cExperiment = append_cExperiment(cExperiment,[],num_timepoints,[],[]);

% run append_cExperiment as many times as necessary to compile all the
% cExperiment files.
% best to delete cellInf before starting.



%% open a GUI to edit the experiment


cExpGUI = experimentTrackingGUI;

%% BEFORE EDITING! (if using a non trap timelapse)
% the non trap timelapse has a few quirks that can make it a bit of a pig.
% These are best solved by following the following steps.

%% change active contour parameters for cExperiment
% this is particularly necessary if the new images are of a different
% maginification. - Skip this step if cells are already annotated

% set some parameters
%cExperiment = cExpGUI.cExperiment;
cExperiment.ActiveContourParameters.ImageTransformation.channel = 1; %set to what you want
cExperiment.ActiveContourParameters.ActiveContour.R_min = 2;
cExperiment.ActiveContourParameters.ActiveContour.R_max = 25;
% bit slower but more fine grained outline for large images.
cExperiment.ActiveContourParameters.ImageSegmentation.OptPoints = 6;

cExperiment.ActiveContourParameters.ImageSegmentation.SubImageSize = 2*(cExperiment.ActiveContourParameters.ActiveContour.R_max + 10) + 1; 

cExperiment.ActiveContourParameters.ActiveContour.alpha = 0.01;
cExperiment.ActiveContourParameters.ActiveContour.beta = 0.01;
cExperiment.ActiveContourParameters.TrapDetection.channel = -1;
cExperiment.ActiveContourParameters.TrapDetection.function = 'forPhaseContrast';
cExperiment.ActiveContourParameters.TrapDetection.functionParams.dilate_length = 2;
cExperiment.ActiveContourParameters.CrossCorrelation.CrossCorrelationValueThreshold = Inf; %don't use mutliple timepoints
cExperiment.ActiveContourParameters.CrossCorrelation.twoStageThresh = 0;
cExperiment.ActiveContourParameters.CrossCorrelation.CrossCorrelationChannel = 1;
cExperiment.ActiveContourParameters.ActiveContour.ShowChannel = 1;

%% run active contour method
poses = 1:2;
cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,poses,1,num_timepoints,true,1,false,false);

%%
% this line runs the tracking and sets the active contour parameters of
% each timelapse to be the active contour parameters of the cExperiment.
% this is useful if using the 'elcoAC' method to add cells.
%This will wipe out all data - do not run this if you have manually
%annotated cells
cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,1:numel(cExperiment.dirs),...
    min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,5,true);

%% editing GUI
% can also use this block of script to curate the cell outline for each
% cell using the curateCellTrackingGUI.

channel_to_curate = 1;

for posi = 1:length(cExperiment.dirs)
    cTimelapse = cExperiment.loadCurrentTimelapse(posi);
    cTimelapse.ACParams = cExperiment.ActiveContourParameters;
    TPs = 1:length(cTimelapse.cTimepoint);
    Traps = cTimelapse.defaultTrapIndices;
    for i = 1:numel(TPs)
        
        TP = TPs(i);
        for TI = Traps
            %gui = curateCellTrackingGUI(cTimelapse,cExperiment.cCellVision,TP,TI,1,channel_to_curate);
            gui = curateCellTrackingGUI(cTimelapse,cCellVision,TP,TI,1,channel_to_curate);
            
            gui.slider.Value = TP;
            gui.slider.Min = TP;
            gui.slider.Max = TP;
            gui.figure.Position = [582 195 939 818];
            uiwait();
        end
    end
    cExperiment.saveTimelapseExperiment;
end


%% refine trap outline
for pos = poses
if_show = true;
cTimelapse = cExperiment.loadCurrentTimelapse(pos);
cTimelapse.refineTrapOutline(cCellVision.cTrap.trapOutline,[],[],if_show)
cExperiment.saveTimelapseExperiment;
end
%% change function
% this is a little annoying but it is also advisable to change the 'method'
% of the cTrapDisplay.addRemoveCells function to 'elcoAC' (line 59). This
% means the cells
% this might get problematic in later versions (or become the standard).

edit cTrapDisplay.addRemoveCells

%% now make sure all cells are selected and look good

% - Annotate cells here using Edit Segmentation button


%% get cExperiment from gui

cExperiment = cExpGUI.cExperiment;
%% make training timelapse from cExperiment - WARNING, generally will load a cCellVision
%  Needs to already be segmented and curated (can't do it afterwards unless non trap timelapse)

%[file,path] = uigetfile('~/Documents/microscope_files_swain_microscope/');
%load(fullfile(path,file),'cExperiment');


for di = 1:length(poses)%1:length(cExperiment.dirs)
    d = poses(di);
    cTimelapse = cExperiment.loadCurrentTimelapse(d);
        if di==1
            cTimelapseAll = fuseTimlapses({cTimelapse});
        else
    cTimelapseAll = fuseTimlapses({cTimelapseAll,cTimelapse});
        end
    clear cTimelapse
    
end

cTimelapse = cTimelapseAll;
clear cTimelapseAll

cTdisp = cTimelapseDisplay(cTimelapse);




%% see trap outline on an image
clear cExperiment currentPos di file path

figure;imshow(OverlapGreyRed(double(cCellVision.cTrap.trap1),cCellVision.cTrap.trapOutline,[],[],true),[]);

%% improve trap outline

%% select image
trap_channel = 1;
TP = randi(length(cTimelapse.cTimepoint),1);
TI = randi(length(cTimelapse.cTimepoint(TP).trapInfo),1);

trap_image = cTimelapse.returnSingleTrapTimepoint(TI,TP,trap_channel);
imshow(trap_image,[])

%% refine

cCellVision.cTrap.trap1 = trap_image;
cCellVision.identifyTrapOutline;


%% show refined trap outline
TP = randi(length(cTimelapse.cTimepoint),1);
TI = randi(length(cTimelapse.cTimepoint(TP).trapInfo),1);

imshow(OverlapGreyRed(double(cTimelapse.returnSingleTrapTimepoint(TI,TP,trap_channel)),full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsBig),[],full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsInner),true),[]);
figure(gcf)




%% make trap_inner region

%%

trap_im = cCellVision.cTrap.trapOutline;

trap_inner = trap_im;

for j = find(sum(trap_im,1)>2)
    
    trap_inner(min(find(trap_im(:,j))):max(find(trap_im(:,j))),j) = true;
end

trap_inner_log = trap_inner;
if false
open_elem = strel('disk',10);
trap_inner = imdilate(trap_inner,open_elem);
trap_inner(:,[1 end]) = false;
trap_inner([1 end],:) = false;
trap_inner = imerode(trap_inner,open_elem);
end

trap_inner_log = trap_inner;
se = fspecial('gauss',[50,50],10);
trap_inner = imfilter(1*(trap_inner & ~trap_im),se);

%trap_inner= trap_inner>1;
%trap_inner(trap_im)=false;
imshow(trap_inner/max(trap_inner(:))+2*trap_im,[]);
figure(2);
imshow(trap_inner_log+2*trap_im,[]);

cCellVision.cTrap.trapInner = trap_inner;
%%
trap_inner_log = imdilate(trap_inner_log & ~trap_im,strel('disk',12));
imshow(trap_inner_log+trap_im,[])

%%
cCellVision.cTrap.trapInnerLog = trap_inner_log & ~trap_im;

%% set segmentation method

%% Elcos BF filter set

SegMethod = @(CSVM,image) createImFilterSetNoTrapSlim(CSVM,image);

%SegMethod = @(CSVM,image) createImFilterSetCellTrap(CSVM,image);

%% very simple classifier for out of focus images

SegMethod = @(CSVM,image) NoTrapVerySlimBadFocus(CSVM,image);

%SegMethod = @(CSVM,image) createImFilterSetCellTrap(CSVM,image);

%% for GFP z stacks (doesn't work very well)

SegMethod = @(CSVM,image) createImFilterSetNoTrapSlimGFP(CSVM,image);

%SegMethod = @(CSVM,image) createImFilterSetCellTrap(CSVM,image);

%% 1 and 3 Bright field classifier.

SegMethod = @(CSVM,image,trapOutline) createImFilterSetElcoBF_1_3(CSVM,image,trapOutline);

%% 1 and 3 Bright field classifier for edges

SegMethod = @(CSVM,image,trapOutline) createImFilterSetElcoBF_1_3_EdgeCentre(CSVM,image,trapOutline);


%% single GFP slice

SegMethod = @(CSVM,image,trapOutline) createImFilterSetElcoGFP_1(CSVM,image);

%% Julian 100x no trap slim
SegMethod = @(CSVM,image) createImFilterSetNoTrapSlim100x(CSVM,image);

%% Slides Brightfield classifier
SegMethod = @(CSVM,image,trapOutline) createImFilterBFStackSlides(CSVM,image,trapOutline);


%% set normalisation method for cCellVision

%% set segmentation channels you want to use

cTimelapse.channelsForSegment =  cTimelapse.selectChannelGUI('segmentation channels',...
                                    'set channels you want to use for segmentation',true);
                                
%% show them
cTimelapseDisplay(cTimelapse);


%%

cCellVision.imageProcessingMethod = 'twostage_norm';
%%
cCellVision.imageProcessingMethod = 'twostage_mean_div';

%% 
cCellVision.imageProcessingMethod = 'wholeIm';

%% check histrogram of images

%Methods for histogram equalisation can be played with - in
%processSegmentationTrapStack method
% not really sure what I hoped to learn from these image but good to know
% that it isn't crazy.
figure;
values = {};
bins = {};
imStacks = {};
for ti = 1:length(cTimelapse.cTimepoint)
    imS = cTimelapse.returnSegmenationTrapsStack(1,ti,cCellVision.imageProcessingMethod);
    imS = imS{1};
    title(sprintf('timepoint %d',ti))
    for slicei = 1:size(imS,3)
        im = imS(:,:,slicei);
       % m = median(im(:));
        %im = (im - m)/iqr(im(:));
        %im = im/iqr(im(:));
        %im = im/median(im(:));
        if ti==1 
            [values{slicei},bins{slicei}] = hist(im(:),200);
            imStacks{slicei} = im;
        else
            [valuestemp] = hist(im(:),bins{slicei});
            values{slicei} = cat(1,values{slicei},valuestemp);
            imStacks{slicei} = cat(3,imStacks{slicei},im);
        end
    end
    
end

for slicei = 1:size(imS,3)
    
    subplot(size(imS,3),1,slicei)
    plot(bins{slicei},log(values{slicei} +1));

end

gui1 = GenericStackViewingGUI(imStacks{1});
gui2 = GenericStackViewingGUI(imStacks{2});

%% look at single image from cCellVision
%TI = 1;
%TP =60;

TP = round(rand*length(cTimelapse.cTimepoint));
TI = round(rand*length(cTimelapse.cTimepoint(TP).trapInfo));



gui = GenericStackViewingGUI;
A =cTimelapse.returnSegmenationTrapsStack(TI,TP);
A = A{1};
figure(4);imshow(cTimelapse.returnSingleTrapTimepoint(TI,TP),[])
gui.stack = A;
gui.LaunchGUI

if cTimelapse.trapsPresent
    trapOutline = full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsBig) + full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsInner);
    trapOutline = trapOutline*0.5;
else
    trapOutline = false(size(A,1),size(A,2));
end

cCellVision.trainingImageExample = A;
%% show filters for this image
if nargin(SegMethod)==3
tic;B = SegMethod(cCellVision,A,trapOutline);toc;
else
    tic;B = SegMethod(cCellVision,A);toc;
end
gui.stack = reshape(B,size(A,1),size(A,2),[]);
gui.normalisation = '';
gui.LaunchGUI;


%% classify image A and show result
%Don't do this unless you have already trained - this is for improving and
%testing cellvisions.
decision_im = cTimelapse.generateSegmentationImages(cCellVision,TP,TI);
%[predicted_im decision_im filtered_image] = cCellVision.classifyImage(A);
gui.stack = cat(3,A,decision_im);
gui.LaunchGUI


%%%%%%%%%%%%%%%%%%%%%%%%%  CENTRE ONLY CLASSIFICATION

%% generate training set
 
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage= floor(0.1*(size(A,1)*size(A,2)));%set to 750 ish for traps and 5000 for whole field images
step_size=50;

debugging = true; %set to false to not get debug outputs
%debugging = false;

debug_outputs  =  cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,SegMethod,debugging);

%debug_outputs = { negatives_stack , positive_stack , neg_exclude_stack}


%% show debug outputs

numTraps = size(debug_outputs{1},3);
debugStack = zeros(size(debug_outputs{1},1),size(debug_outputs{1},2),numTraps*3);
nT = 1;
nTr = 1;
nTrT = 1;
show_channel = 1;
while nTrT<=numTraps
    TrapIm = cTimelapse.returnTrapsTimepoint([],nT,show_channel);
    for iT = 1:size(TrapIm,3)
        image_to_show = repmat(double(TrapIm(:,:,iT)),[1,1,3]);
        image_to_show = image_to_show.*(1 + ...
        cat(3,debug_outputs{1}(:,:,nTrT),debug_outputs{2}(:,:,nTrT),debug_outputs{3}(:,:,nTrT)));
        image_to_show = (image_to_show - min(image_to_show(:)))./(max(image_to_show(:)) - min(image_to_show(:)));
        debugStack(:,:,3*nTrT + [-2 -1 0]) = image_to_show;
        nTrT = nTrT + 1;
    end
    fprintf('timepoint nT of some\n')
    nT = nT +step_size;
    
    
end

gui.stack = debugStack;
gui.type = 'tri-stack';
gui.LaunchGUI;


%% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2
cCellVision.trainingParams.gamma=1
%% parameter grid search
%cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
ws = [sum(cCellVision.trainingData.class==1)/sum(cCellVision.trainingData.class==0) 1];
%ws = round(ws./min(ws,[],2));
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); %sets negative weights to be such that total of negative and positive is hte same
maxTP = 1000;
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); % set step size so never using more than 30 timepoints
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

%% save
% you can now save the cellVision. We normally save it once as is. i.e
% save('some/path/and/file.mat','cCellVision')
% and once without it's training data. This is the one that you should use
% for analysis.
% cCellVision.trainingData = [];
% save('some/other/path/and/file.mat','cCellVision')
% 




%%%%%%%%%%%%%%%%%%%%%%%%%  EDGE CLASSIFICATION

%% clear old
cCellVision.SVMModel = [];
cCellVision.SVMModelGPU = [];
cCellVision.SVMModelLinear = [];

%% generate training set
 
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage= floor(0.2*(size(A,1)*size(A,2)));%set to 750 ish for traps and 5000 for whole field images
step_size=1;

debugging = true; %set to false to not get debug outputs
%debugging = false;

debug_outputs  =  cCellVision.generateTrainingSetTimelapseCellEdge(cTimelapse,step_size,SegMethod,debugging);

%debug_outputs = { negatives_stack , positive_stack , neg_exclude_stack}
fprintf('\n  training set obtained \n')

%% show debug outputs
% red = inner
% blue = edge
% green = outer
numTraps = size(debug_outputs{1},3);
debugStack = zeros(size(debug_outputs{1},1),size(debug_outputs{1},2),numTraps*3);
nT = 1;
nTr = 1;
nTrT = 1;
show_channel = 1;
while nTrT<=numTraps
    TrapIm = cTimelapse.returnTrapsTimepoint([],nT,show_channel);
    for iT = 1:size(TrapIm,3)
        image_to_show = repmat(double(TrapIm(:,:,iT)),[1,1,3]);
        image_to_show = image_to_show.*(1 + ...
        cat(3,debug_outputs{2}(:,:,nTrT),debug_outputs{1}(:,:,nTrT),debug_outputs{5}(:,:,nTrT)));
        image_to_show = (image_to_show - min(image_to_show(:)))./(max(image_to_show(:)) - min(image_to_show(:)));
        debugStack(:,:,3*nTrT + [-2 -1 0]) = image_to_show;
        nTrT = nTrT + 1;
    end
    fprintf('timepoint nT of some\n')
    nT = nT +step_size;
    
    
end

gui.stack = debugStack;
gui.type = 'tri-stack';
gui.LaunchGUI;


%% CELL TO OUTER 
fprintf('\n\n    grid search cell to outer SVM \n\n')

% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2;
cCellVision.trainingParams.gamma=1;
% parameter grid search
%cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
ws = [(sum(cCellVision.trainingData.class==1)+sum(cCellVision.trainingData.class==2))/sum(cCellVision.trainingData.class==0) 1];
%ws = round(ws./min(ws,[],2));
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); %sets negative weights to be such that total of negative and positive is hte same
maxTP = 30;
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); % set step size so never using more than 30 timepoints
cCellVision.runGridSearchCellToOuterLinear(step_size,cmd);
% linear training

fprintf('\n\n    training cell to outer SVM \n\n')

maxTP = 100; 

step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); 
%cCellVision.trainingParams.cost=1;
%cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];

cmd=sprintf('-s 1 -w0 %f -w1 %f -c %f'...
    ,ws(1),ws(2),cCellVision.trainingParams.cost); %sets positive and negative weights to be such that total of negative and positive is the same

tic
cCellVision.trainSVMCellToOuterLinear(step_size,cmd);toc




% INNER TO EDGE

fprintf('\n\n    grid search inner to edge SVM \n\n')


% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2;
cCellVision.trainingParams.gamma=1;
% parameter grid search
%cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
ws = [sum(cCellVision.trainingData.class==1)/sum(cCellVision.trainingData.class==2) 1];
%ws = round(ws./min(ws,[],2));
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); %sets negative weights to be such that total of negative and positive is hte same
maxTP = 30;
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); % set step size so never using more than 30 timepoints
cCellVision.runGridSearchInnerToEdgeLinear(step_size,cmd);
% linear training

fprintf('\n\n    training edge to inner SVM \n\n')

maxTP = 100; 

step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP) ; 1]); 
%cCellVision.trainingParams.cost=1;
%cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];

cmd=sprintf('-s 1 -w0 %f -w1 %f -c %f'... 
   ,ws(1),ws(2),cCellVision.trainingParams.cost); %sets positive and negative weights to be such that total of negative and positive is the same

% might be faster but not sure of the implications.
% cmd=sprintf('-s 2 -w0 %f -w1 %f -c %f'...
%     ,ws(1),ws(2),cCellVision.trainingParams.cost); %sets positive and negative weights to be such that total of negative and positive is the same

t= tic;
cCellVision.trainSVMInnerToEdgeLinear(step_size,cmd);toc(t)

% flip second model
% This was necessary when I trained the model, but I'm not sure it will
% always be the case. Performing this made the centres in the InnerToEdge
% classifiers negative, and the edges positive, but didn't change the
% actual scores.
cCellVision.SVMModelInnerToEdgeLinear.Label = [0;1];
cCellVision.SVMModelInnerToEdgeLinear.w = -cCellVision.SVMModelInnerToEdgeLinear.w;


%% classify image A and show result
%Don't do this unless you have already trained - this is for improving and
%testing cellvisions.
[~, decision_im, ~,raw_SVM_res]=classifyImage2Stage(cCellVision,A,trapOutline>1);
%[predicted_im decision_im filtered_image] = cCellVision.classifyImage(A);
gui.stack = cat(3,A,decision_im,raw_SVM_res);
gui.LaunchGUI


%% open a timelapse to check how good it is

disp = experimentTrackingGUI






%% stuff from here on is for the two stage classifier, which no one uses anymore (slow, little benfit)


%% 
%From matt's original code, doesn't seem to do anything but make very
%similar data structure but renamed. Try using below instead

maxTP = 200;
step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
cCellVision.generateTrainingSet2Stage(cTimelapse,step_size);

%% just use same data for training two stage and linear

cCellVision.trainingData.kernel_features = cCellVision.trainingData.features;
cCellVision.trainingData.kernel_class = cCellVision.trainingData.class;

%% classify linear data (taken from classify image 2 stage)

classes = cCellVision.trainingData.class;

normalised_features=(cCellVision.trainingData.features - repmat(cCellVision.scaling.min,size(cCellVision.trainingData.features,1),1));
normalised_features=normalised_features*spdiags(1./(cCellVision.scaling.max-cCellVision.scaling.min)',0,size(normalised_features,2),size(normalised_features,2));

labels=ones(size(normalised_features,1),1);
dec_values=zeros(size(normalised_features,1),1);
predict_label=zeros(size(normalised_features,1),1);

% mex file that does the linear prediction.
[~, ~, dec_valuesLin] = predict(labels, sparse(normalised_features), cCellVision.SVMModelLinear); % test the training data]\


% report

fprintf('non cell pixels: %2.2f %% correct \n cell pixels: %2.2f %% correct\n',...
    100*sum(dec_valuesLin>0 & ~ismember(cCellVision.trainingData.class',[1,2]))/sum(~cCellVision.trainingData.class),...
    100*sum(dec_valuesLin<0 & ismember(cCellVision.trainingData.class',[1,2]))/sum(cCellVision.trainingData.class));

%% use to select kernel features

kernel_features = [];
kernel_classes = [];

total_2stage_features = 60000;
fraction_cell_selected = 0.05;
fraction_non_cell_selected = 0.05;

% cell pixels
I = find(classes ==1);
dec_valuesLin_cells = dec_valuesLin(I);
[~,I2] = sort(abs(dec_valuesLin_cells));
I = I(I2(1:floor(min(fraction_cell_selected*total_2stage_features,length(I)))));

kernel_features = cat(1,kernel_features,cCellVision.trainingData.features(I,:));
kernel_classes = cat(2,kernel_classes,cCellVision.trainingData.class(I));

%non cell pixels
I = find(classes ==0);
dec_valuesLin_non_cells = dec_valuesLin(I);
[~,I2] = sort(abs(dec_valuesLin_non_cells));
I = I(I2(1:floor(min(fraction_non_cell_selected*total_2stage_features,length(I)))));

kernel_features = cat(1,kernel_features,cCellVision.trainingData.features(I,:));
kernel_classes = cat(2,kernel_classes,cCellVision.trainingData.class(I));

%random pixels

I = randperm(length(classes),ceil(min(total_2stage_features*(1- (fraction_cell_selected+ fraction_non_cell_selected)),length(classes))));
kernel_features = cat(1,kernel_features,cCellVision.trainingData.features(I,:));
kernel_classes = cat(2,kernel_classes,cCellVision.trainingData.class(I));

cCellVision.trainingData.kernel_features = kernel_features;
cCellVision.trainingData.kernel_class = kernel_classes;


%% attemps to find a refined set of features
linear_weights = cCellVision.SVMModelLinear.w;

[x,I] = sort(abs(linear_weights),'descend');

features_to_keep = I(1:20);
cCellVision.trainingData.kernel_features = cCellVision.trainingData.features(:,features_to_keep);
cCellVision.trainingData.kernel_class = cCellVision.trainingData.class;


%% two stage grid search
maxTP= 2;

ws = [sum(cCellVision.trainingData.kernel_class==1)/sum(cCellVision.trainingData.kernel_class==0) 3];
%ws = round(ws./min(ws,[],2));
cmd=sprintf('-s 0 -t 2 -w0 %f -w1 %f',ws(1),ws(2)); %sets negative weights to be such that total of negative and positive is hte same

%step_size=max(1,floor(length(cTimelapse.cTimepoint)/maxTP)); 
step_size = 2;
tic
cCellVision.runGridSearch(step_size,cmd);
toc

fprintf('grid search complete \n')
%
maxTP = 1;
%ws = [sum(cCellVision.trainingData.class==1)/sum(cCellVision.trainingData.class==0) 1];
%step_size=max(length(cTimelapse.cTimepoint),floor(length(cTimelapse.cTimepoint)/maxTP)); 
step_size = 1;
cmd = sprintf('-s 0 -t 2 -w0 %f -w1 %f -c %f -g %f',ws(1),ws(2),cCellVision.trainingParams.cost,cCellVision.trainingParams.gamma);
tic
cCellVision.trainSVM(step_size,cmd);toc

fprintf('two stage training complete \n')

%% classify an image

[predicted_im, decision_im, filtered_image]=classifyImage2Stage(cCellVision,A,trapOutline);

figure;imshow(A(:,:,1),[]);
imtool(decision_im,[]);


%% classify with two stage

% CRASHES MATLAB FOR SOME REASON - FIX
n = 10;

I = randperm(length(classes),n);

normalised_2stage_features = normalised_features(I,:);
classes_2stage = classes(I);

labels=ones(size(normalised_2stage_features,1),1);
dec_values=zeros(size(normalised_2stage_features,1),1);
predict_label=zeros(size(normalised_2stage_features,1),1);

% mex file that does the linear prediction.
[a, ~, dec_values_2stage] = predict(labels, (normalised_2stage_features), cCellVision.SVMModel); % test the training data]\

   
% report

fprintf('non cell pixels: %2.2f %% correct \n cell pixels: %2.2f %% correct\n',...
    100*sum(dec_values_2stage>0 & ~classes_2stage')/sum(~class_2stage),...
    100*sum(dec_values_2stage<0 & classes_2stage')/sum(classes_2stage));


  

%% classify images and see

for TP = 1%:length(cTimelapse.cTimepoint);

traps_to_check = 1:length(cTimelapse.cTimepoint(TP).trapInfo);

tic;DecisionImageStack = cTimelapse.generateSegmentationImages(cCellVision,TP,traps_to_check);toc
TrapStack = double(cTimelapse.returnSingleTrapTimepoint(traps_to_check,TP));

DecisionImageStack = DecisionImageStack./(2*max(abs(DecisionImageStack(:))));
DecisionImageStack = DecisionImageStack -min(DecisionImageStack(:));
TrapStack = TrapStack./max(TrapStack(:));

view_gui = GenericStackViewingGUI(cat(2,DecisionImageStack,TrapStack));
uiwait()
end



%%

%% classify images and see
f = fspecial('disk',3);
thresh = -0.3;
for TP = 180%1:length(cTimelapse.cTimepoint);

traps_to_check = 1:length(cTimelapse.cTimepoint(TP).trapInfo);

DecisionImageStack = cTimelapse.generateSegmentationImages(cCellVision,TP,traps_to_check);
TrapStack = double(cTimelapse.returnSingleTrapTimepoint(traps_to_check,TP));

DIM2 = imfilter(DecisionImageStack,f,'same');
DIM2(DecisionImageStack>thresh) = DecisionImageStack(DecisionImageStack>thresh);

DecisionImageStack = DecisionImageStack./(2*max(abs(DecisionImageStack(:))));
DecisionImageStack = DecisionImageStack -min(DecisionImageStack(:));
TrapStack = TrapStack./max(TrapStack(:));

view_gui = GenericStackViewingGUI(cat(2,DecisionImageStack,TrapStack));
uiwait()
end



G = fspecial('gaussian',[5 5],2);
%# Filter it
Ig = imfilter(I,G,'same');
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



