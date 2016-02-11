function standard_extraction_cExperiment(cExperiment,poses,maxTP,do_segment,do_track,do_AC,do_extract,do_lineage,params)
%standard_extraction_cExperiment(cExperiment,poses,maxTP,do_segment,do_track,do_AC,do_extract,do_lineage,params)
%
% function to do the most standard segmentation. Written so that
% cExperiment files can be segmented in script
%
% poses         :   indices of positions to extract
% maxTP         :   maximum timepoint used in consecutive timepoint
%                   segmentation
% do_segment    :   number. 1=> do segmentation and tracking continuous
%                           2=> do segmentation and tracking after
%                           experiment
%                           anything else => nothing
% do_track      :   track cells and do 
% do_AC         :   (boolean). do active contour method
% do_extract    :   (boolean). extract data
% do_lineage    :   (boolean). do lineage tracking
% params        :   a structure of parameters. See
%                   standard_extraction_cExperiment_default for details.
% 
%
if nargin<4
do_segment = 1;
end

if nargin<5
do_track = true;
end


if nargin<6
do_AC = true;
end

if nargin<7
do_extract = true;
end

if nargin<8
do_lineage= true;
end

if nargin<9
    file_name = mfilename('fullpath');
    run([file_name '_parameters_default'])
end

paramsLineage = params.paramsLineage;
paramsCellSelect = params.paramsCellSelect;
paramsCombineTracklet = params.paramsCombineTracklet;


% cell identification, equivalent to the 'identify cells' button. Uses a
% support vector machine, encoded by cCellVision, to identify cells in the
% timelapse. Can either be run after the experiment is completed or while
% it is still running.
if do_segment==1
    cExperiment.trackTrapsOverwrite = true;
    cExperiment.segmentCellsDisplayContinuous(cExperiment.cCellVision,poses,maxTP)
    cExperiment.trackTrapsOverwrite = false;
elseif do_segment==2
    cExperiment.trackTrapsOverwrite = true;
    cExperiment.segmentCellsDisplay(cExperiment.cCellVision,poses)
    cExperiment.trackTrapsOverwrite = false;
end

% tracks the cells from one timepoint to the next using a modified
% euclidean distance which takes account of changes in cell size from one
% timepoint to the next and punishes shrinking cells more in the tracking.
%
% followed by a post processing step that combines tracks of very similar
% cells separated by a short period.
if do_track
    cExperiment.trackCells(poses,params.trackingDistance);
    combineTracklets(cExperiment,poses,paramsCombineTracklet);
end

% equivalent to the Run Active Contour button, selecting method 1. Uses an
% active contour method, ideally on out of focus Brightfield images, to
% find a more accurate outline of the cell than the circles found by
% 'identify cells'.
% With the standard method this requires the cells to be found and tracked.
if do_AC
    cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,poses,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,2,false,false);
end

% extracts the data and compiles it in cExperiment.cellInf.
% equivalent to pressing the following in order:
% AutoSelect
% Extract Data
% Compile Data

if do_extract
    cExperiment.selectCellsToPlotAutomatic(poses,paramsCellSelect);
    
    cExperiment.extractCellInformation(poses,false);
    
    cExperiment.compileCellInformation(poses);
    
end

% perfroms daughter identification and lineage tracking based in a hidden
% markov model of daughter events.
if do_lineage
    
    cExperiment.extractLineageInfo(poses,paramsLineage);
    
    cExperiment.compileLineageInfo(poses);
    
    cExperiment.extractHMMTrainingStates;
    
    cExperiment.trainBirthHMM;
    
    cExperiment.classifyBirthsHMM;
    
end

cExperiment.saveExperiment;

end