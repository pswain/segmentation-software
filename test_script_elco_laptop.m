%% test script laptop

% this is a script for testing the segmentation software on Elco's laptop.
% It's fairly crude, mostly just makes sure the different types of
% segmentation work.

l1 = load('c:\Users\elcob_000\Documents\work\microscope analysis\str81_2015_07_07\traps_few_test\cExperiment.mat');
cExperiment = l1.cExperiment;
cExperiment.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'few traps standard';
%

cExperiment.trackTrapsInTime(poses);

cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,poses,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,1,false,false);
%
% % retrack
params = standard_extraction_cExperiment_parameters_default(cExperiment,poses);
%cExperiment.trackCells(poses,params.trackingDistance);

%extract
cExperiment.selectCellsToPlotAutomatic(poses,params.paramsCellSelect);
cExperiment.extractCellInformation(poses,false);
cExperiment.compileCellInformation(poses)

l1 = load('c:\Users\elcob_000\Documents\work\microscope analysis\str81_2015_07_07\traps_few_reference\cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


compareExperimentTrackingObjsForTest(cExperiment,cExperiment_true,poses, report_string )
