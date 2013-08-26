%% Create class and identify folders with fields of views
cExperiment=experimentTracking;
searchString{1}='DIC';
% searchString{2}='GFP';
magnification=60;
image_rotation=0;
timepointsToLoad=1:1:3e3;
cExperiment.loadTimelapsePositions(searchString,'all',magnification,image_rotation,timepointsToLoad);
%% Select which traps you want to track
cExperiment.identifyTrapsTimelapses(cCellVision);
%% Load whichever cCellVision file you think is the most appropriate and best for the data set
%%This opens a window to display the timelapses as they are being
%%segmented. By default it goes through all positions in the cExperiment
cExperiment.segmentCellsDisplay(cCellVision);
%% To Visualize the cells from all traps, and correct any mistakes 
% This doesn't have to be run
cExperiment.visualizeSegmentedCells(cCellVision,1);
%% Track cells
cExperiment.trackCells();
%% Select which cells to plot
%below opens windows for you to select cells
% cExperiment.selectCellsToPlot(cCellVision,1);

%below automatically selects which cells stay in traps for a long time
params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=3e3; %number of frames cells must be present
params.framesToCheck=30;
cExperiment.selectCellsToPlotAutomatic(params);
save([cExperiment.rootFolder '/cExperiment'],'cExperiment');

%% Extract information from the cellsToPlot
cExperiment.extractCellInformation();
save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
%% 