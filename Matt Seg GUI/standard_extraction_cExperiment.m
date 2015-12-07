function standard_extraction_cExperiment(cExperiment,poses,maxTP,do_segment,do_track,do_AC,do_extract,do_lineage)
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
    
    paramsCombineTracklet.fraction=.1; %fraction of timelapse length that cells must be present or
    paramsCombineTracklet.duration=3; %number of frames cells must be present
    paramsCombineTracklet.framesToCheck=(max(cExperiment.timepointsToProcess));
    paramsCombineTracklet.framesToCheckEnd=1;
    paramsCombineTracklet.endThresh=2; %num tp after end of tracklet to look for cells
    paramsCombineTracklet.sameThresh=4; %num tp to use to see if cells are the same
    paramsCombineTracklet.classThresh=3.8; %classification threshold
    
    combineTracklets(cExperiment,poses,paramsCombineTracklet);
end

if do_AC
    cExperiment.RunActiveContourExperimentTracking(cExperiment.cCellVision,poses,min(cExperiment.timepointsToProcess),max(cExperiment.timepointsToProcess),true,2,false,false);
end

if do_extract
    cTimelapse=cExperiment.returnTimelapse(poses(1));
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=4;  %length(cTimelapse.cTimepoint); %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.timepointsProcessed);
    params.framesToCheckEnd=1;
    params.maximumNumberOfCells = Inf;
    cExperiment.selectCellsToPlotAutomatic(poses,params);
    
    cExperiment.extractCellInformation(poses,false);
    
    cExperiment.compileCellInformation(poses);
    
end

if do_lineage
    params.motherDurCutoff=params.framesToCheck/4;
    params.motherDistCutoff=8;
    params.budDownThresh=0;
    params.birthRadiusThresh=7;
    params.daughterGRateThresh=-1;
    cExperiment.extractLineageInfo(poses,params);
    
    
    cExperiment.compileLineageInfo;
    
    cExperiment.extractHMMTrainingStates;
    
    cExperiment.trainBirthHMM;
    
    cExperiment.classifyBirthsHMM;
    
end

cExperiment.saveExperiment;

end