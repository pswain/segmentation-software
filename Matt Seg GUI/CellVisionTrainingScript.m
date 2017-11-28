%% Elco's cCellVision training script

%% creating a totally new cellVision model
% if creating a totally new cellVision model, run the following 2 blocks of
% code.
%% load a cExperiment
% use the usual GUI or create a cExperiment from images or load one that
% has already been created
cExpGUI = experimentTrackingGUI;

%% select new trap image
% use the images from this cExperiment to create the initial trap template
% for the cellVision model. This is also a opportunity to set the scaling -
% shrinking images if they are larger than you need to do the segmentation.
% In general, we use a scaling such that most mother cells are around 12
% pixels wide. 
%After this has been created, save the cellVision model and
% use it to select all the traps in all the experiments you will compile
pos = 1;
cCellVision = cellVision.createCellVisionFromExperiment(cExpGUI.cExperiment,pos);

%% save
cCellVision.saveCellVision;

%% COMMENCE CURATION
% from here we assume you have done the above, creating experiments in
% which traps have been selected using the cellVision above or an old
% cellVision you are retraining. It is important that the traps have
% already been selected at this stage. It is also often common, if
% retraining an old cellVision model, to have run the active contour over
% these experiments.

%% initialise for cExperiment compilation
% this sets up some variables for the compilation of experiments.
cExperiment =[];
% num_timepoints : this is the number of time points that will be selected
% randomly from each experiment appended.
num_timepoints = 5; 
% pick_pairs : if this is true the timepoints will be picked in consecutive
% pairs (meaning that num_timepoints * 2 timpoints will actually get
% selected). This is only useful if the same curated experiment will be used
% for both the CellVision training and the shape space training (which is
% only currently implemented for trap timelapses).
pick_pairs = false;
% reefine_trap_outline : setting this to true will cause the trap outlines
% to be refined. This is done based on the
% cExperiment.ActiveContourParameters.TrapDetection parameter structure. It
% is recommended, however, it can make the cExperiment difficult to use in
% other contexts (i.e. outside of training) and the performance of the
% refinement will depend on trapDetection parameters set for each of the
% cExperiments merged, and should be inspected (see below).
refine_trap_outline = true;

%% select cExperiments you want to add to the gound truth set.
% num_timpoints timepoints will be added from each one (with the pick_pairs
% caveat detailed above) distributed evenly over the timelapse. In our
% experience, 30 timepoints (total) over a few experiments are sufficient
% and manageable.
% With the settings below, cExperiment files are selected by GUI.

cExperiment = append_cExperiment(cExperiment,[],num_timepoints,[],[],[],[],pick_pairs,refine_trap_outline);

%% editing GUI
% The below block is the most convenient way to edit the cells outlines. It
% opens successive cellCurationGUIs, in which one can add/remove cell,
% alter their outline or fix their tracking (fixing tracking is only
% necessary if you wish to use the same experiment for cell shape
% training).
% Press 'h' to see the help for this GUI on all the many shortcut keys.
% 
% CAVEAT: the curation will only be saved when you have finished curating a
% whole position. If there are a few timepoints per positions, you may want
% to bear in mind you are sitting down to a substantial task that is hard
% to pause. If you wish to curate the cells in a more leisurely manner,
% keeping a record of which timepoints/traps have been curated, we
% recommend using tracking functions of the compareExperiment object
% (though there is some overhead in learning how to set this up, the object
% help should be clear).

% positions: these are the position you will curate, and should usually be
% all unless you are coming back to curation after having stopped it.
positions = 1:length(cExperiment.dirs);

% figure position: this can be used to set the position of the figure. It
% is useful if you wish to make the figure larger without having to resize
% it every time. To work out a size you like, open a figure, get it to a
% good size, and then run f=gcf;f.Position
figure_position = [];

% if this is true it will show you the timepoints as consecutive pairs.
% This is useful if you set 'pick_pairs' to true in your cExperiment fusing
% selection above and wish to curate the tracking at the same time for use
% with the shape training later.
do_pairs = false;

cExperiment.curateCells(positions,figure_position,do_pairs);


%% BEGIN TRAINING
% having completed the steps above your cExperiment, compiled out of
% multiple experiments, should be completely curated:
% all cells outlined and checked
% the refined trap outlines having been checked
%
% we will now begin the actual training.

%% make training timelapse from cExperiment 
% the training script works on a single large timelapse. This block
% converts the cExperiment into one large timelapse for processing. Once
% this is done it is hard to edit, so all curation should have been
% completed.
% At the end, it will show you the large, fused cTimelapse.

positions = 1:length(cExperiment.dirs);

for di = 1:length(positions)
    d = positions(di);
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


%% make trapInnerLog region
% this block is suppose to identify the 'inner region' of the trap - the
% area where cells are most likely to be. I have left it open since you may
% want to play with it and rerun it to accurately pick out the area of
% interest.
% the image shown shows the traps as bright, the inner region as grey and
% the rest as black.
% it doesn't need to be super accurate, it's only used for preferentially
% selecting negative points for the training.
% If you have no traps, you don't need to run this block.

dilate_length = 12;

trap_im = cCellVision.cTrap.trapOutline;

trap_inner = trap_im;

for j = find(sum(trap_im,1)>2)
    
    trap_inner(min(find(trap_im(:,j))):max(find(trap_im(:,j))),j) = true;
end


trap_inner_log = trap_inner;

trap_inner_log = imdilate(trap_inner_log & ~trap_im,strel('disk',dilate_length));
imshow(trap_inner_log+2*trap_im,[])

% write to cellVision for use in ground truth generation.
cCellVision.cTrap.trapInnerLog = trap_inner_log & ~trap_im;


%% set segmentation method
% the SegMethod is the function that will be applied to the images to
% generate the features by which the pixels are classified. 
% They are generally stored in the 
%       ElcoCellIdentificationFilterSets 
% folder and should all return an NxMxL image stack when passed an NxM
% image (this stack is the L the features used to classify the pixels).
% They can also use the trapOutline in generating their features. 
%
% WARNING: If you wish to modify a function (adding,removing or altering
% features) it is STRONGLY RECOMMEDED that you make a NEW file, with a new
% name, and modify this. This prevents your modifications breaking
% cellVIsion models that have been trained with the current version of a
% function.
%
% It is highly likely that many of the features we use could be removed,
% making the whole process faster.

%% 1 and 3 Bright field classifier for interior and  edges
SegMethod = @(CSVM,image,trapOutline) createImFilterSetElcoBF_1_3_EdgeCentre(CSVM,image,trapOutline);

%% Slides Brightfield classifier
SegMethod = @(CSVM,image,trapOutline) createImFilterBFStackSlides(CSVM,image,trapOutline);


%% set segmentation channels you want to use
% aswell as setting the segmentation method, you have to set the channels
% on which you want the segMethod to act. This can be any number of
% channels, but more channels will make it bother slower to calculate all
% the features and increase the chance of overfitting - (i.e. making the
% cellVision model very good on the training set but not particularly good
% on real data).
% we usually use 2 brightfield channels (one above and one below) or just
% one channel of the two are not available.

cTimelapse.channelsForSegment =  cTimelapse.selectChannelGUI('segmentation channels',...
                                    'set channels you want to use for segmentation',true);
                                
%% set image normalisation method for cCellVision
% before an image is processed by the classifier, a normalisation procedure
% is usually applied. This is done because often images from different days
% or microscopes will vary wildly in brightness, and it is important that
% they are all brought into the same range for the classifier to work well.
% Making sure this normalisation works well is one of the main reasons to
% fuse various experiments when training.
% 
% There are a number of normalisation options to choose from below along
% with some code to 'check' the normalisation. Unfortunately the actual
% code for doing these normalisations is somewhat buried in the 
%
%       timelapseTraps.processSegmentationTrapStack
%
% method. So if none of these work and you wish to make a new one, you may
% have to dig into some fairly preplexing code.  


%%
% this is what we use for normal traps. It is normalised by the difference
% between the 2nd and 98th percentile of the pixel values, which tends to
% work well since the traps determine the extremes of the image brightness.
cCellVision.imageProcessingMethod = 'twostage_norm';
%%
% divide the image by the mean of the image. Fairly dependenable,
% particularly for image without traps.
cCellVision.imageProcessingMethod = 'twostage_mean_div';

%% check normalisation of images
% the following block of code applies the image normalisation to all the
% images that will be used in the training and shows you the result in 2
% ways.
% 1- a plot of all the pixel brightness histograms after normalisation.
% 2- a set of GUI's in which each image is shown 'raw' i.e. with the
%    normalisation applied but no further normalisation applied for
%    visualisation.
% If the normalisation method is working correctly, the histograms should
% lie on top of each other and the images should all look similarly bright.
% If some look very bright and some look very dim, the normalisation is not
% working correctly and should be changed.

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
    xlabel('pixel intensity')
    ylabel('density')
    title(cTimelapse.channelNames{cTimelapse.channelsForSegment(slicei)})

end

gui1 = GenericStackViewingGUI(imStacks{1});
gui1.title = cTimelapse.channelNames{cTimelapse.channelsForSegment(1)};

gui2 = GenericStackViewingGUI(imStacks{2});
gui2.title = cTimelapse.channelNames{cTimelapse.channelsForSegment(2)};

%% look at single image from cCellVision
% this selects a random image from the training set which will be used for
% visualisation throughout the training procedure. The images selected will
% also be stored with the cellVision to show users what the channels it was
% trained with look like, so it is worth running this a few times till you
% get a 'representative' image.

TP = round(rand*length(cTimelapse.cTimepoint));
TI = round(rand*length(cTimelapse.cTimepoint(TP).trapInfo));



gui = GenericStackViewingGUI;
example_image =cTimelapse.returnSegmenationTrapsStack(TI,TP);
example_image = example_image{1};
figure;imshow(cTimelapse.returnSingleTrapTimepoint(TI,TP),[])
gui.stack = example_image;
gui.LaunchGUI

if cTimelapse.trapsPresent
    trapOutline = full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsBig) + full(cTimelapse.cTimepoint(TP).trapInfo(TI).refinedTrapPixelsInner);
    trapOutline = trapOutline*0.5;
else
    trapOutline = false(size(example_image,1),size(example_image,2));
end

cCellVision.trainingImageExample = example_image;
%% show filters for this image
% this block of code will show you all the features for the example image.
% Interpretation of features is tricky, but it can give some clue as to
% whether something is not being 'well represented' by the features or is
% giving very little information.
if nargin(SegMethod)==3
    tic;example_image_features = SegMethod(cCellVision,example_image,trapOutline);toc;
else
    tic;example_image_features = SegMethod(cCellVision,example_image);toc;
end
gui.stack = reshape(example_image_features,size(example_image,1),size(example_image,2),[]);
gui.normalisation = '';
gui.LaunchGUI;



%%%%%%%%%%%%%%%%%%%%%%%%%  EDGE CLASSIFICATION

% the following blocks of code are used to build the edge/centre/background
% classifiers as presented in the paper. Code for the older centre/other
% classifier can be found below in the 'junk' section.

%% clear old
% if the cellVision model had previously been trained, this will clear
% those models out.
cCellVision.SVMModel = [];
cCellVision.SVMModelGPU = [];
cCellVision.SVMModelLinear = [];

%% generate training set
% this block of code generates the training set. i.e. the values of all the
% pixel features with their associatiated classes. All edge and interior
% pixels are included and the a subset of the background pixels. Trap
% pixels are excluded from the training set.
% 
% This block can take some time if the training set is large.

% this is the number of background pixels used in the image. The value
% chosen here is usually reasonable.
cCellVision.negativeSamplesPerImage = floor(0.2*(size(example_image,1)*size(example_image,2)));

% if step_size is larger than 1 than only every 'step_size' image will be
% used (for example, a step_size of 5 means every 5th image). 1 is usually
% fine for constructing the training set, but you may wish to set it larger
% if the training set is very large.
step_size=1;

% this should be left true so that outputs can be inspected.
debugging = true; 

debug_outputs  =  cCellVision.generateTrainingSetTimelapseCellEdge(cTimelapse,step_size,SegMethod,debugging);

fprintf('\n  training set obtained \n')



%% show training set
% the following block of code is quite useful to make sure nothing has gone
% wrong and all is as you expect. It shows a GUI in which traps are shown
% with the training set highlighted in the following colour code:
% red = inner 
% blue = edge 
% green = outer
% scan through them to see that everything is as you expect. If not you may
% need to repeat some of the steps above (such as curation).
% If there are many more/less red pixels (negative samples)than the other
% colours in most images than you may need to make the training set again,
% decreasing/increasing the negativeSamplesPerImage field. 

% this is the channel index over which the traps samples will be overlaid.
show_channel = cTimelapse.channelsForSegment(1);

numTraps = size(debug_outputs{1},3);
debugStack = zeros(size(debug_outputs{1},1),size(debug_outputs{1},2),numTraps*3);
nT = 1;
nTrT = 1;
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
gui.title('training set overlay')
gui.LaunchGUI;

%% save
% at this point it is usually a good idea to save the workspace in case
% something goes wrong. It can sometimes happen that the classification
% overwhelms matlab and the program has to be closed without the option to
% save first.
%% Train 
% the following large block of code will train the two classifiers
% (background to cell and cell interior to edge). This canbe rather memory
% demanding, can take a long time, and if the training set is too large it
% can crash matlab/your computer.

% these are the maximum allowed size of the training set for grid search
% and training. If the training set is larger than this the training set is
% sub sampled.
% If training is very quick this can be increased. If it is too slow or
% your computer crashes it should be decreased. One can tell from the
% printed prompts if it is the grid search of the training which is
% fast/slow.
maxTP_gridsearch = 30;
maxTP_training = 100; 

% CELL TO OUTER classifier
fprintf('\n\n    grid search cell to outer SVM \n\n')


cCellVision.trainingParams.cost=2;
cCellVision.trainingParams.gamma=1;

% weights are set to try and give equal weigh to the two classes, whatever
% the number of samples.
ws = [(sum(cCellVision.trainingData.class==1)+sum(cCellVision.trainingData.class==2))/sum(cCellVision.trainingData.class==0) 1];

% sets step size so never using more than maxTP_gridsearch timepoints
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP_gridsearch) ; 1]); 

% parameter grid search
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); 
cCellVision.runGridSearchCellToOuterLinear(step_size,cmd);


fprintf('\n\n    training cell to outer SVM \n\n')

step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP_training) ; 1]); 

cmd=sprintf('-s 1 -w0 %f -w1 %f -c %f'...
    ,ws(1),ws(2),cCellVision.trainingParams.cost); 

tic
cCellVision.trainSVMCellToOuterLinear(step_size,cmd);toc




% INNER TO EDGE

fprintf('\n\n    grid search inner to edge SVM \n\n')


cCellVision.trainingParams.cost=2;
cCellVision.trainingParams.gamma=1;

%sets negative weights to be such that total of negative and positive is hte same
ws = [sum(cCellVision.trainingData.class==1)/sum(cCellVision.trainingData.class==2) 1];

% set step size so never using more than maxTP_gridsearch timepoints
step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP_gridsearch) ; 1]); 

% parameter grid search
cmd=sprintf('-s 1 -w0 %f -w1 %f -v 5 -c ',ws(1),ws(2)); 
cCellVision.runGridSearchInnerToEdgeLinear(step_size,cmd);


fprintf('\n\n    training edge to inner SVM \n\n')

step_size=max([floor(length(cTimelapse.cTimepoint)/maxTP_training) ; 1]); 

cmd=sprintf('-s 1 -w0 %f -w1 %f -c %f'... 
   ,ws(1),ws(2),cCellVision.trainingParams.cost); 

t= tic;
cCellVision.trainSVMInnerToEdgeLinear(step_size,cmd);toc(t)

% flip second model
% This was necessary when I trained the model, but I'm not sure it will
% always be the case. Performing this made the centres in the InnerToEdge
% classifiers negative, and the edges positive, but didn't change the
% actual scores.
cCellVision.SVMModelInnerToEdgeLinear.Label = [0;1];
cCellVision.SVMModelInnerToEdgeLinear.w = -cCellVision.SVMModelInnerToEdgeLinear.w;


%% remove training data and save cellVision
% the training data is quite large, so we normally remove it before saving
% the cellVision for use. If you need to retrain the cellVision model
% (chaning step sizes or negative samples for example), use the workspace
% you saved above before training.
%
% You can now load this cellVision model and apply it to segment
% experiments.
cCellVision.trainingData = [];
cCellVision.saveCellVision;

%% %%%%%%%%%%%%%%%%%%%% JUNK  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stuff below here is junk that no one uses anymore. It is left in for
% posterity and for those who wrote the software and may still want to use
% it. There is no guarantee any of it works.



%%%%%%%%%%%%%%%%%%%%%%%%%  CENTRE ONLY CLASSIFICATION

%% generate training set
 
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage= floor(0.1*(size(example_image,1)*size(example_image,2)));%set to 750 ish for traps and 5000 for whole field images
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

[predicted_im, decision_im, filtered_image]=classifyImage2Stage(cCellVision,example_image,trapOutline);

figure;imshow(example_image(:,:,1),[]);
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

tic;DecisionImageStack = cTimelapse.generateSegmentationImages(TP,traps_to_check);toc
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

DecisionImageStack = cTimelapse.generateSegmentationImages(TP,traps_to_check);
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
 example_image = cCellVision.trainingData.features;
 example_image_features = cCellVision.trainingData.class;
 
cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,@(CSVM,image) createImFilterSetCellTrap_Reduced(CSVM,image));
if any(example_image(:)~= cCellVision.trainingData.features(:)) || any(example_image_features(:) ~= cCellVision.trainingData.class(:))
    fprintf('\n problem with function handle type operation \n')
end



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



%% show refined trapOutline
% show the refined trap outlines identified earlier. Might help to identify
% if cells are not being found where expected. If the coloured superimposed
% outline does not accurately match the traps.
for diri=poses
    cTimelapse = cExperiment.loadCurrentTimelapse(diri);
    for tp = cTimelapse.timepointsToProcess
        im = cTimelapse.returnTrapsTimepoint([],tp,2);
        for ti = 1:length(cTimelapse.cTimepoint(tp).trapInfo)
            imshow(OverlapGreyRed(im(:,:,ti),full(cTimelapse.cTimepoint(tp).trapInfo(ti).refinedTrapPixelsInner),[],...
                full(cTimelapse.cTimepoint(tp).trapInfo(ti).refinedTrapPixelsBig),true),[]);
            title(sprintf('pos: %d tp: %d trap: %d',diri,tp,ti))
            pause(0.1);
            
        end
    end
end

