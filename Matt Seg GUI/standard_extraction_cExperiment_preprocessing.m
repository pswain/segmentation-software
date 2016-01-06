%% preprocessing script for cExperiment files.

% COPY THIS FILE TO A NEW LOCATION BEFORE CHANGING IT FOR YOUR OWN USES.

%this script is intended as a preprocessing script that will also detail
%the various functions that are standardly called in processing a
%cExperiment.

%% GUI
% make the analysis GUI for loading/creating cExperiments and editing the
% results. This GUI allows easy access to the editing functions

cExpGUI = experimentTrackingGUI;

% use the 'create cExperiment' or 'load cExperiment' to load the default
% load a cExperiment.

%% load a cTimelapse
% the cExperiment object organises cTimelapse objects - one for each
% position. One is loaded here for easy access to some of its properties,
% but it will not be saved by default. 
% 
% Here we also make the cExperiment object accessible. Since it is a handle
% object, changes to it will also affect the cExperiment object in the
% cExpGUI.
%
% poses is a list of all positions which is generally useful.
cTimelapse = cExpGUI.cExperiment.loadCurrentTimelapse(1);
cExperiment = cExpGUI.cExperiment;
poses = 1:length(cExperiment.dirs);

%% add channels
% corresponding to the 'add Channel' button, which does the same thing
% individually. Adds the other channels (i.e. those in addition to DIC) to
% the cExperiment so that they are accessible in the processing and data
% extraction.

channels = {'GFP','cy5'};

for chi=1:length(channels)
    cExperiment.addSecondaryChannel(channels{chi});
end

%% set TP to process
% often it is not desirable to process all timepoints (for example, if the
% device becomes clogged at the end). In order to only process a part of
% the experiment click the 'Tp to process' button, or run:

cExperiment.selectTPToProcess;

%% setting offset

% the different channels acquired can be 'offset' with respect to each
% other. i.e. it might be necessary to shift them a pixel or two
% up/down/left/right to get them to 'overlap' properly. This is done using
% the setChannelOffset method of the cExperiment.

%% try an offset

% here we set the offset of the DIC channel by comparing it to another
% channel (GFP) and checking the outcome by eye. DIC is most often poorly
% registered with the other channels. 
% Play with the offset assignment and see how the outcome looks.

DICch = 1;
GFPch = 5;
timepoint = 200;

cTimelapse.offset(1,:) = [-1 0];
im1 = double(cTimelapse.returnSingleTimepoint(timepoint,DICch));
im2 = double(cTimelapse.returnSingleTimepoint(timepoint,GFPch));

figure(5);
imshow(OverlapGreyRed(im1,im2),[]);

%% set offset
% having found a good offset above, we set it for all positions.
cExpGUI.cExperiment.setChannelOffset;

%% set flat field (optional)
% often a fluorescent has an uneven illumination, and therefore response,
% across the field. This can be compensated by provided a flat field
% correction, by which an image is premultiplied before it is returned. 
%
% Elco has some methods for finding this, but it is generally the inverse
% of an image of a fluorescent slide if constant brightness. It is set
% using the following method.

cExpGUI.cExperiment.setBackgroundCorrection(BGcorrGFP)


%% editing the cellVision trap outline (optional)
% this is not necessary if the timelapse does not have traps.
% the cellVision model, used for identifying cells, has an outline of the
% trap which is used to 'blot out' trap pixels in the cell detection. This
% can be improved, sometimes improving the cell detection, using the
% following code.
%
% first select a single trap in position 1.

cExperiment.identifyTrapsTimelapses(cExperiment.cCellVision,1,false);

% this function will then use that image of the trap to try and refine the
% trap outline - with user intervention. Instructions should be clear, if
% in doubt press enter.

cExpGUI.cExperiment.editCellVisionTrapOutline(1,1,1,1)

%% now select traps for all positions.
% the selection of the traps defines the areas in which the code will look
% for cells, and also sets up the organisation of the 

cExperiment.identifyTrapsTimelapses(cExperiment.cCellVision)


%% if intending to run the active contour method
% there is an active contour methd, but it only works well if out of focus
% DIC or. ideally, Brightfield images are available. It is rather slow but
% can improve the quality of data.
%f you intend to run it you need to add the out of focus DIC/brightfield channels:

%%

cExperiment.addSecondaryChannel('Brightfield_001');
cExperiment.addSecondaryChannel('Brightfield_003');
%%
% then set the following parameters:
% (these are only correct if you have added the channels as prescribed -
% adjust as necessary).
lower_brightfield_channel = 4; % lower z stack slice of brightfield
upper_brightfield_channel = 5; % upper z stack slice of brightfield

cExperiment.ActiveContourParameters.ImageSegmentation.channels = [lower_brightfield_channel -upper_brightfield_channel];

%% adjust extraction parameter
% there are a number of parameters for the extraction. These are set by the
% following function, which would be called from the GUI if you press the
% extract Data button.

cExperiment.setExtractParameters([],cExperiment.guiSetExtractParameters);

%% set cell identification threshold
% two stage threshold sets the leneancy of cell identification. Higher is
% will find more cells, lower is more stringent.

cExperiment.cCellVision.twoStageThresh = 0;

%% standard processing.
% the following will do the standard processing of the cExperiment, which
% may take several days depending on the parameters selected and the
% length/size of the experiment.
% standard_extraction_cExperiment has details of the functions called.
%
% this uses the standard_extraction_cExperiment_parameters_user.m' file. 

% whether and how to identify the cells. possible value: 
% 0 - do not identify cells (if already done)
% 1 - identify cells in an experiment that has been completed. 
% 2 - identify cells in an experiment that is currently
% running. if the experiment is currently running, tracking(the next
% parameter) is not neccessary
do_segment = 1;

% This is used if the extraction is currently running, and sets the
% expected length of the experiment. If this is never reached the
% cell identification will run forever and have to be stopped by ctrl C.
% not used if experiment is completed (do_segment = 1)
maxTP = 200;

% whether or not to track the cells through time. 
% necessary to do for the first segmentation and to use the active contour
% methods.
do_track = true; 

% do the active contour method(optional). 
% equivalent to pressing the 'Run Active Contour' button and choosing the
% first method ('Active contour on found and tracked centres').
% See above for more details.

do_AC = true;
% whether or not to extract and compile the data.
% equivalent to the 'Extract Data' button followed the 'Compile Data'
% button.
do_extract = true;


% do the lineage tracking/birth identification.
do_lineage  = true;


%% parameter function for standard_extraction_cExperiment_preprocessing
% these are copied from the default parameter script.

params = struct;

% combine tracklets parameters:
% used for combining tracks that seem to be the same cell but have been
% tracked as two different cells.
paramsCombineTracklet.fraction=.1; %fraction of timelapse length that cells must be present or
paramsCombineTracklet.duration=3; %number of frames cells must be present
paramsCombineTracklet.framesToCheck=(max(cExperiment.timepointsToProcess));
paramsCombineTracklet.framesToCheckEnd=1;
paramsCombineTracklet.endThresh=2; %num tp after end of tracklet to look for cells
paramsCombineTracklet.sameThresh=4; %num tp to use to see if cells are the same
paramsCombineTracklet.classThresh=3.8; %classification threshold

params.paramsCombineTracklet = paramsCombineTracklet;

% parameters for automatic cell selection
cTimelapse=cExperiment.returnTimelapse(poses(1));
paramsCellSelect.fraction=.8; %fraction of timelapse length that cells must be present or
paramsCellSelect.duration=4;  %length(cTimelapse.cTimepoint); %number of frames cells must be present
paramsCellSelect.framesToCheck=length(cTimelapse.timepointsProcessed); % time before which a cell must arrive to be considered.
paramsCellSelect.framesToCheckEnd=1; %timepoint after which a cell must arrive for it to be considered a cells.
paramsCellSelect.maximumNumberOfCells = Inf; %maximum number of cells to extract

params.paramsCellSelect = paramsCellSelect;

% parameters for lineage info.
% need to fill in details of what they are.
paramsLineage = paramsCellSelect;
paramsLineage.motherDurCutoff=paramsLineage.framesToCheck/4; 
paramsLineage.motherDistCutoff=8;
paramsLineage.budDownThresh=0;
paramsLineage.birthRadiusThresh=7;
paramsLineage.daughterGRateThresh=-1;

params.paramsLineage = paramsLineage;

params.trackingDistance = 5; % threshold of distance between cells at one timpoint and the next. Higher implies more lenient tracking.


%% run extraction

standard_extraction_cExperiment(cExperiment,poses,maxTP,do_segment,do_track,do_AC,do_extract,do_lineage,params);


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



