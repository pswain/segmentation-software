%%%%  TEST SCRIPT FOR SEGMENTATION SOFTWARE %%%%%%%

%This is a fairly crude test script that applies the major steps of the
%segmentation software and checks if the outcome has changed. THe two
%cExperiments loaded should be identical copies of each other, the
%processing steps are then done to the 'test' version before finally being
%compared with the 'true' version. Two versions are required since the
%cTimelapse objects get overwritten. This can easily be acheived using the
%copyExperiment method of cExperiments.
%
%It is advisable to arrange them to be small. The separation into two
%chunks is done so that the tracking and mother detection can be tested on
%a longer timelapse.



%% test cell identification, tracking and identification on very short timelapse

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;



poses = 1:2;
cExperiment_test.trackTrapsOverwrite = true;
cExperiment_test.segmentCellsDisplay(cExperiment_test.cCellVision,poses)
cExperiment_test.trackTrapsOverwrite = false;

cExperiment_test.trackCells(poses,5);

paramsCombineTracklet.fraction=.1; %fraction of timelapse length that cells must be present or
    paramsCombineTracklet.duration=3; %number of frames cells must be present
    paramsCombineTracklet.framesToCheck=(max(cExperiment_test.timepointsToProcess));
    paramsCombineTracklet.framesToCheckEnd=1;
    paramsCombineTracklet.endThresh=2; %num tp after end of tracklet to look for cells
    paramsCombineTracklet.sameThresh=4; %num tp to use to see if cells are the same
    paramsCombineTracklet.classThresh=3.8; %classification threshold
    
combineTracklets(cExperiment_test,poses,paramsCombineTracklet);

%
%cExperiment_test.RunActiveContourExperimentTracking(cExperiment_test.cCellVision,poses,min(cExperiment_test.timepointsToProcess),max(cExperiment_test.timepointsToProcess),true,2,false,false);

%
% select cells

cTimelapse=cExperiment_test.returnTimelapse(poses(1));
params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=4;  %length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=length(cTimelapse.timepointsToProcess);
params.framesToCheckEnd=1;
params.maximumNumberOfCells = Inf;
cExperiment_test.selectCellsToPlotAutomatic(poses,params);

cExperiment_test.extractCellInformation(poses,'max',[5 6 7]);

cExperiment_test.compileCellInformation(poses);


if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test\n')
else
    fprintf('\n             FAILED standard processing test\n')
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'))
    
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing test timelapse %d',diri)
    else
        fprintf('\n         FAILED standard processing test timelapse %d',diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri))
        
    end
    
end

fprintf('\n\n')

%%

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_2_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_2/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

poses = 1:2;

cExperiment_test.trackCells(poses,5);

paramsCombineTracklet.fraction=.1; %fraction of timelapse length that cells must be present or
    paramsCombineTracklet.duration=3; %number of frames cells must be present
    paramsCombineTracklet.framesToCheck=(max(cExperiment_test.timepointsToProcess));
    paramsCombineTracklet.framesToCheckEnd=1;
    paramsCombineTracklet.endThresh=2; %num tp after end of tracklet to look for cells
    paramsCombineTracklet.sameThresh=4; %num tp to use to see if cells are the same
    paramsCombineTracklet.classThresh=3.8; %classification threshold
    
combineTracklets(cExperiment_test,poses,paramsCombineTracklet);

params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=4;  %length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=length(cExperiment_true.timepointsToProcess);
params.framesToCheckEnd=1;
params.maximumNumberOfCells = Inf;


cExperiment_test.selectCellsToPlotAutomatic(poses,params);

cExperiment_test.extractCellInformation(poses,'max',[5 6 7]);

cExperiment_test.compileCellInformation(poses);


params.motherDurCutoff=params.framesToCheck/4;
params.motherDistCutoff=8;
params.budDownThresh=0;
params.birthRadiusThresh=7;
params.daughterGRateThresh=-1;
cExperiment_test.extractLineageInfo(poses,params);

cExperiment_test.compileLineageInfo;

cExperiment_test.extractHMMTrainingStates;
%
cExperiment_test.trainBirthHMM;


cExperiment_test.classifyBirthsHMM;


if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test\n')
else
    fprintf('\nFAILED standard processing test\n')
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'))
        
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing test timelapse %d',diri)
    else
        fprintf('\n         FAILED standard processing test timelapse %d',diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri))
        
    end
    
end

fprintf('\n\n')



