function standard_extraction_cExperiment(cExperiment,poses,maxTP,do_segment,do_track,do_AC,do_extract,do_lineage,params)
%standard_extraction_cExperiment(cExperiment,maxTP,poses,do_AC,do_Extract,do_lineage)
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


if do_segment==1
    cExperiment.trackTrapsOverwrite = true;
    cExperiment.segmentCellsDisplayContinuous(cExperiment.cCellVision,poses,maxTP)
    cExperiment.trackTrapsOverwrite = false;
elseif do_segment==2
    cExperiment.trackTrapsOverwrite = true;
    cExperiment.segmentCellsDisplay(cExperiment.cCellVision,poses)
    cExperiment.trackTrapsOverwrite = false;
end
if do_track
    cExperiment.trackCells(poses,5);
    combineTracklets(cExperiment,poses,paramsCombineTracklet);
end

if do_AC
    cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,poses,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,2,false,false);
end

if do_extract
    cExperiment.selectCellsToPlotAutomatic(poses,paramsCellSelect);
    
    cExperiment.extractCellInformation(poses,false);
    
    cExperiment.compileCellInformation(poses);
    
end

if do_lineage
    
    cExperiment.extractLineageInfo(poses,paramsLineage);
    
    cExperiment.compileLineageInfo;
    
    cExperiment.extractHMMTrainingStates;
    
    cExperiment.trainBirthHMM;
    
    cExperiment.classifyBirthsHMM;
    
end

cExperiment.saveExperiment;

end