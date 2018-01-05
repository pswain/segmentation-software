%% processing script for cExperiment files.

% COPY THIS FILE TO A NEW LOCATION BEFORE CHANGING IT FOR YOUR OWN USES.

%this script is intended as a processing script that will also detail
%the various functions that are standardly called in processing a
%cExperiment.

%% GUI
% make the analysis GUI for loading/creating cExperiments and editing the
% results. This GUI allows easy access to the editing functions

cExpGUI = experimentTrackingGUI;

% To create an experiment from a folder containing image files use the
% "Create New Experiment" or  "Load Experiment" button. To create an
% experiment from the Omero image database click on the Omero icon. This
% brings up a 2nd GUI in which you can browse for the dataset you want to
% segment. Click the "Load" button in that GUI to create an experiment for
% segmentation. cExperiment files created from the Omero database are
% automatically saved as part of the source dataset after segmentation, data
% extraction etc.

% In the cExperiment creation GUI you will be asked to provide a channel.
% This is the one you will generally see when viewing images, so something
% near the centre of the brightfield stack or DIC is advisable. 
% It is also VERY IMPORTANT that this field appear in all timepoints of all
% positions (i.e. is not skipped or starts after timepoint 1) and appears
% ONLY ONCE (so 'brightfield_' is not a good idea if you took brightfield z
% stacks).
%% add channels
% corresponding to the 'add Channel' button, which does the same thing
% individually. Adds the other channels (i.e. those in addition to initial
% Brightfield channel) to the cExperiment so that they are accessible in
% the processing and data extraction.
%This step is not necessary for cExperiments created from the Omero
%database as they should have all channels added automatically

%channels = {'Brightfield_001','Brightfield_003','Brightfield_004','Brightfield_005','GFP','GFP_001','GFP_002','GFP_003','GFP_004','GFP_005','tdTomato','tdTomato_001','tdTomato_002','tdTomato_003','tdTomato_004','tdTomato_005'};
channels = {'Brightfield_001','Brightfield_003','GFP','GFP_001','GFP_002','GFP_003'};
channels = {'Brightfield_001','Brightfield_003','GFP'};

cExpGUI.cExperiment.addSecondaryChannel(channels);


% this block of code will ensure those channels are visible in the cExpGUI
set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
cExpGUI.channel = 1;

fprintf('done adding channels \n')

%% select poses
% running the following code will define poses as those positions
% highlighted in the GUI.
% These will be the positions processed by the rest of the script.

poses = cExpGUI.posList.Value;

%% make cExperiment object accessible
% Here we also make the cExperiment object accessible. Since it is a handle
% object, changes to it will also affect the cExperiment object in the
% cExpGUI.

cExperiment = cExpGUI.cExperiment;




%% set TP to process
% often it is not desirable to process all timepoints (for example, if the
% device becomes clogged at the end). In order to only process a part of
% the experiment click the 'Tp to process' button, or run:

cExperiment.selectTPToProcess;


%% load a cCellVision

% We now load the cCellVision model. This object contains information for
% both identifying traps in the images and for classifying pixels as either
% cell centre or not cell centre.

% You will also have to set segmentation channels:
% You have to match the channels from your segmentation to the imaging
% channels used in training the cCellVision. This is not straightforward,
% since the imaging conditions (such as z stack distance) will affect which
% channels are appropriate. If in doubt, ask the person who trained the
% CellVision model or someone who uses it regularly.

%% load from GUI
% open a GUI to select a cCellVsion from anywhere
cExperiment.loadCellVisionByGUI;
%% load standard brightfield classifier
l1 = load('./Matt Seg GUI/cCellvisionFiles/default_cCellVision.mat');
cExperiment.cCellVision = l1.cCellVision;
%cExpGUI.cCellVision = l1.cCellVision;

cExperiment.setSegmentationChannels;

%% load standard DIC classifier
l1 = load('./Matt Seg GUI/cCellvisionFiles/cCellVision_DIC_default.mat');
cExperiment.cCellVision = l1.cCellVision;

cExperiment.setSegmentationChannels;



%% editing the cellVision trap outline (optional)
% this is not necessary if the timelapse does not have traps.

% The cellVision model, used for identifying cells, has an outline of the
% trap which is used to 'blot out' trap pixels in the cell detection. This
% can be improved, sometimes improving the cell detection, using the
% following code.
%
% this function will first ask you to select a channel for trap selection.
% This should be a channel in which the traps are clear and maximally
% distinguishable from the cells.
%
% You will then be required to select a single, representative trap. 
%
% the software will then require you to select trap features and edit the
% outline it finds for them by clicking on the images displayed. This
% generally requires a furious amount of clicking while slowly moving the
% cursor around the trap. Annoying, but it was an easy way to allow a large
% range of trap outlines and imaging modalities.
% If in doubt - press enter.
%
% Finally, it will show you an overlap image of the representative trap and
% the refined trap outline. When you are finised inspecting this image,
% close it. If you are not satisfied with it, rerun this block of code and
% try again.

cExpGUI.cExperiment.editCellVisionTrapOutline(poses(1),1)

%% if you don't do the above set the trap detection channel to the lower brightfield channel

cExperiment.ActiveContourParameters.TrapDetection.channel = 1;

%% now select traps for all positions.
% This is still necessary even if you don't have traps but will not ask you
% to do anything.
%
% The selection of the traps defines the areas in which the code will look
% for cells, and also sets up the organisation of the cTimelapse.

cExperiment.identifyTrapsTimelapses(poses)


%% adjust autoselect parameters
% these are the parameters that will be used to automatically select cells
% for which data will be extracted. If you intend to use daughter data
% (i.e. extract births) it is best to make this lenient.

cExperiment.selectCellSelectParamsGUI();
%% adjust extraction parameter
% there are a number of parameters for the extraction. These are set by the
% following function, which would be called from the GUI if you press the
% extract Data button.

extraction_parameters = cExperiment.guiSetExtractParameters;
cExperiment.setExtractParameters([],extraction_parameters);




%% ELco Standard extraction

%% inspect decision image

% The decision image is the output of the cCellVision model, and is an
% image in which cell centres should have low values and everything else
% (edges,non cell regions) should have high values.
%
% We here inspect the decision image for a particular timepoint to help us
% choose the decision image thresholds. i.e. those values in the decision
% image at which the software determines a pixel to be the centre of a
% cell. Lower values are more stringent, n  while higher ones are more
% lenient. 
% 
% The software uses two thresholds, one for new cells (more stringent -
% thresh1 below) and one for cells that were present at previous time
% points (more lenient - thresh2 below). In order to pick these, we will
% look at a visualisation of the decision image with pixels below the
% different thresholds coloured yellow and green.

%% pick position and timepoint to inspect.

tp = 1; % time point to inspect
channel_to_view = 1; % channel on which to overlay thresholds
pos = poses(1); % position to inspect

%% track this position 
% The traps in this position must first be tracked 
% This only needs to be run on the first occasion and then if you
% pick a different position to inspect (i.e. the result is saved for a
% particular position). If you want to go back and change the thresholds,
% inspect different timepoints etc. you do not need to run this again.
%
% this still needs to be run if you have no traps.

cExperiment.trackTrapsInTime(pos);


%% calculates the decision image
% this only needs to be run the first time you inspect a particular
% timepoint of a particular position. (i.e. if you change the thresholds
% and reimage you don't re run this s tage.

cTimelapse = cExpGUI.cExperiment.loadCurrentTimelapse(pos);
cTimelapse.ACParams = cExpGUI.cExperiment.ActiveContourParameters;

num_traps = length(cTimelapse.cTimepoint(tp).trapInfo);

tic;
DIM = cTimelapse.generateSegmentationImages(tp,1:num_traps);
toc;

%% opens the 3 images with colors
% This block of code opens three images:
%   - the decision image in an imtool window so pixel values can be seen by
%     hovering over
%   - a compiled image of all traps at the timepoint in that position
%   - another compiled image of all traps at the timepoint in that position
%     but with pixels below the given thresholds overlaid in colour.
% This block of code can be rerun numerous times, changing the thresholds
% in the code block 3 above to see different thresholds overlaid on the
% trap image.

% Show the following thresholds:
thresh1 = -1.5; %yellow: new cells (more stringent)
thresh2 = -0.5; % green : tracked cells (less stringent)

trapImage = cTimelapse.returnTrapsTimepoint(1:num_traps,tp,channel_to_view);
mega_image_size = ceil(sqrt(num_traps));

min_DIM = min(DIM(:));

DIM(:,:,(end+1):(mega_image_size^2)) = min_DIM;
trapImage(:,:,(end+1):(mega_image_size^2)) = min(trapImage(:));

mega_image = [];
mega_trap_image = [];

n = 1;
for i=1:mega_image_size
    temp_col = [];
    temp_col2 = [];
    temp_col_acwe = [];
    for j=1:mega_image_size
        temp_col = [temp_col;DIM(:,:,n)];
        temp_col2 = [temp_col2;trapImage(:,:,n)];
       
        n = n+1;
    end
    mega_image = [mega_image temp_col];
    mega_trap_image = [mega_trap_image temp_col2];
    

end
imtool(mega_image,[])
figure;imshow(OverlapGreyRed(mega_trap_image,mega_image<thresh1,[],mega_image<thresh2,true),[])
figure;imshow(mega_trap_image,[])


% set Active Contour parameters
% having selected the thresholds above, we now set the active contour
% parameters appropriately.

% new cells:
cExperiment.ActiveContourParameters.CrossCorrelation.twoStageThresh = thresh1; % update with the color

% tracking cells that are there
cExperiment.ActiveContourParameters.CrossCorrelation.CrossCorrelationDIMthreshold = thresh2;
cExperiment.ActiveContourParameters.CrossCorrelation.CrossCorrelationValueThreshold = ...
                        cExperiment.ActiveContourParameters.CrossCorrelation.CrossCorrelationDIMthreshold;



%% Look at the results for the test position
% it is often useful to look at the results from a single position and see
% if anything is strange. 
% we here run the active contour algorithm on test position we were using
% for inspecting the decision image earlier. When you are happy that you v
% have seen enough, press ctrl C to stop it.

% this line just sets which channel is shown in the gui as it is
% segmenting.
cExperiment.ActiveContourParameters.ActiveContour.ShowChannel = cTimelapse.channelsForSegment(1);

cExperiment.RunActiveContourExperimentTracking(pos,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,1,false,false);

%% Actual long run (Elco standard extraction); run when happy with all the rest!
% this block is the actual extraction for the whole experiment. It will
% usually take a day.


%track traps
cExperiment.trackTrapsInTime(poses);
 
% identification and active contour
cExperiment.RunActiveContourExperimentTracking(poses,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,1,false,false);

% retrack
params = standard_extraction_cExperiment_parameters_default(cExperiment,poses);
%cExperiment.trackCells(poses,params.trackingDistance);
%
% automatically select cells
cExperiment.selectCellsToPlotAutomatic(poses);

%extract
cExperiment.extractCellInformation(poses,false);
cExperiment.compileCellInformation(poses)


% get mother index
for diri=poses
    
    cTimelapse = cExperiment.loadCurrentTimelapse(diri);
    cTimelapse.findMotherIndex;
    cExperiment.cTimelapse = cTimelapse;
    cExperiment.saveTimelapseExperiment(diri,false);

    
end

% mother processing
paramsLineage = params.paramsLineage;
cExperiment.extractLineageInfo(poses,paramsLineage);
cExperiment.compileLineageInfo(poses);
cExperiment.extractHMMTrainingStates;
cExperiment.trainBirthHMM;
cExperiment.classifyBirthsHMM;

% save experiment 
cExperiment.saveExperiment;




%% OTHER USEFUL FUNCTIONS

%% changing the location of images:
% when you move a cExperiment from one computer to another, you need to
% make two changes:
% first the saveFolder field needs to be changed to the location of the
% cExperiment.
% then the image locations need to be changed to their location on the
% current computer.
cExperiment.saveFolder = uigetdir;
cExperiment.changeRootDirAllTimelapses;

%% setting offset
% this stage can usually be ignored but is included for completeness.

% the different channels acquired can be 'offset' with respect to each
% other. i.e. it might be necessary to shift them a pixel or two
% up/down/left/right to get them to 'overlap' properly. This is done using
% the setChannelOffset method of the cExperiment.

%% try an offset
% this stage can usually be ignored but is included for completeness.

% here we set the offset of the DIC channel by comparing it to another
% channel (GFP) and checking the outcome by eye. DIC is most often poorly
% registered with the other channels. 
% Play with the offset assignment and see how the outcome looks.

cTimelapse = cExperiment.loadCurrentTimelapse(poses(1));

DICch = 1;
GFPch = 6;
timepoint = 100;

cTimelapse.offset(1,:) = [0 0];
im1 = cTimelapse.returnSingleTimepoint(timepoint,DICch);
im2 = cTimelapse.returnSingleTimepoint(timepoint,GFPch);

im1 = (im1-min(im1(:)))/iqr(im1(:));
im2 = (im2-min(im2(:)))/iqr(im2(:));

figure(5);
imshow(OverlapGreyRed(im1,im2),[]);

%% set offset
% this stage can usually be ignored but is included for completeness.

% having found a good offset above, we set it for all positions.
cExpGUI.cExperiment.setChannelOffset;

%% set flat field (optional)
% this stage can usually be ignored but is included for completeness.

% often a fluorescent channel has an uneven illumination, and therefore
% response, across the field. This can be compensated by providing a flat
% field correction, by which an image is premultiplied before it is
% returned.
%
% Elco has some methods for finding this, but it is generally the inverse
% of an image of a fluorescent slide of constant brightness. It is set
% using the following method.

cExpGUI.cExperiment.setBackgroundCorrection(BGcorrGFP)
%BGcorrGFP is the image by which the final image will be premultiplied.

%% Use old image transform methods for finding edges
% By default the software use the cellVision model to identify edges as
% well as centres. If you would prefer to use an image transform to detect
% edges instead (the old way of doing the processing) you can set the
% parameters as described below.
%
% this flag will tell the software not to use the result from the
% cellVision model (which will meaningless if it has not yet been trained)
% and to instead use the image transform to find the edge.
cExperiment.ActiveContourParameters.ImageTransformation.EdgeFromDecisionImage = false;

% in general a channel must be specified on which to perform the
% transformation. The default transformation works well on images where the
% cell is a bright object surrounded by a dark halo. If only the inverse is
% available (a dark object with a white halo, such as in phase contrast),
% one can use - the channel index. e.g
% lower_brighfield_channel = -2;
lower_brighfield_channel = 2;
cExperiment.ActiveContourParameters.ImageTransformation.channel = lower_brightfield_channel;

% if these settings do not provide good results, one can dive into the
% other available transformation stored in 
%   ActiveContourFunctions/+ACImageTransformations
