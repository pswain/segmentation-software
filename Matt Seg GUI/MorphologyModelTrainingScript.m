%%%%%%%%%%%%%%%%%% CELL MORPHOLOGY MODEL TRAINING SCRIPT %%%%%%%%%%%%%%%%%%

% This script covers the training of the cell morphology model - the model
% of how the cell shape and location changes in the trap. It is trained
% based on an experimentTracking object (cExperiment) that has been curated
% in time point pairs. i.e. has been selected and curated as sets of
% consecutive timepoint pairs. If you haven't done this, or you aren't sure
% what it means, look at the CellVisionTrainingScript.m

%% training a cellMorphology model with a different number of radii
% the cell outline is determined by
% experimentTracking.ActiveContourParameters.ACparams.opt_points.
% if you want to use a different numebr of radii, to get a coarser or more
% detailed outline, you will have to change this parameter and then train
% an entirely newMorphology model, processing and curating the images with
% this number of opt_points. To do this, use the following method to make a
% cellMorphologyModel and set cExperiment.cCellMorph to this object, and
% then process the whole experiment anew.
%
% this will also require setting the follow parameters;
% cExperiment.ActiveContourParameters.ActiveContour.inflation_weight = 0;
% p.CrossCorrelation.ThresholdCellProbability = 0;
% p.CrossCorrelation.ThresholdCellScore = Inf;

BlankCellMorph = cellMorphologyModel.makeInocuousCellMorphModel(opt_points,average_cell_radius);

%% create cellMorphologyModel
% like the cellVision model, this is a class to extract training data and
% train the model.

cCellMorph = cellMorphologyModel;

%% load cExperiment
% load the experiment That you wish to use to train the cell shape model.
% Again, this should be a cExperiment in which shape and tracking have been
% curated as sets of matched time point pairs.

[file,path] = uigetfile('*.mat','selected the curated cExperiment file');
l = load(fullfile(path,file));
l.cExperiment.cCellVision = l.cCellVision;

%% extract data
% this extracts the training data from the cExperiment.

cCellMorph.extractTrainingDataFromExperiment(l.cExperiment);

%% train new cell shape model
% this trains the new cell shape model - the model applied to cells when
% they are first discovered. The training will show 2 plots: 
% - one is a single bar plot that shows the asymptotic p value of the
% Jarque Bera statistic for each parameter (the radii of the active contour
% method) individually. 
% - the second a set of subplots, each with a histogram of the radii from
% the training data and a plot of the gaussian that would be fitted to them
% individually.
% Ideally the asymptotic p values should be low - below the red line - and
% the fitted gaussians should be close to the data. If they aren't there's
% not much to do and it is unlikely to affect performance dramatically.
%
% the method has one parameter: method, which is either 'tp1' or 'new_only'
%  tp1 - will train the shape model on all cells at timepoint 1.
%  new_only - will train it only on those cells at time point 2 that
%  WEREN'T present at tp1. 
% 'new_only' is better if you have a large enough data set (over 1000
% curated pairs).

method = 'tp1';

cCellMorph.inspectAndTrainNewCellModel(method);


%% train tracked shape model
% this is the same as above but for the tracked cell model - the model used
% to evaluate the shape of cells that are tracked from one timepoint to the
% next. There are no parameters and it shows the same plots - this time
% performed on the log normalised radii (normalised to the previous timepoint
% and logged) for both small and large cells.
%
% as part of the training it will request 1 parameter by user interface -
% the threshold cell radius that distinguishes small and large cells. The
% default value should be good, but if you have a reason for thinking that
% a particular size is important you can submit that instead.

cCellMorph.inspectAndTrainTrackedCellModel;

%% sample cell shapes
% This is really just for fun, and shows 'sampled cell shapes' i.e. ones
% generated from the model, at consecutive timepoints with light grey
% showing the previous timepoint.
% These should look somewhat like cells.
timepoints=5;
cCellMorph.sampleShapeModel([],timepoints);

%% sample small cell
% asabove but starts as a small cell, so should behave slightly
% differently.
timepoints=8;
starting_radii = (cCellMorph.thresh_tracked_cell_model/2)*cCellMorph.mean_new_cell_model/(max(cCellMorph.mean_new_cell_model));
cCellMorph.sampleShapeModel(starting_radii,timepoints);


%% train motion model
% trains the model of how cells move in the traps. Requires no parameters
% and shows 3 plots:
% 1 - a log proability plot for the prior based on cell location (this is
% shown as an image GUI)
% 2 - a log proability plot for the prior based on cell size (this is
% shown as an image GUI)
% 3 - a plot of cell radius against distance moved. This last can be
% important since it also shows the edges of the bins into which cells are
% grouped when deciding their 'size motion prior'. However, it's not very
% important and can be left as default.
%
% each successive GUI has to be closed

cCellMorph.inspectAndTrainMotionModel;

%% save
% most are save in the cCellMorphFiles folder.
cCellMorph.saveCellMorphologyModel;



