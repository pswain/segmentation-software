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



% IMPORTANT NOTE ON PARFOR LOOP
% because parfor loop is run in non-deterministic order, loops must be
% made normal for loops IF they include the use of random numbers for this
% script to work. 
% strangely, this is not true for single core computers (like my laptop)
% but is true even if you start parfor with only 1 worker on a multicore
% machine. 

%% load generic
l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/traps_few_test/cExperiment.mat');
cExperiment = l1.cExperiment;
cExperiment.cCellVision = l1.cCellVision;
cCellVision = cExperiment.cCellVision;
cTimelapse = cExperiment.loadCurrentTimelapse(1);


%%
clc
clear all
close all

%% normal timelapse
% start at a specific seed - should lead to the same outcome every time.
rng('default')
rng(1)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/traps_few_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'few traps standard';
%
l2 = load('/Users/ebakker/SkyDrive/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellMorphFiles/old_cCellMorph.mat');
cExperiment_test.cCellMorph = l2.cCellMorph;
cExperiment_test.trackTrapsInTime(poses);

cExperiment_test.RunActiveContourExperimentTracking(cExperiment_test.cCellVision,poses,min(cExperiment_test.timepointsToProcess),max(cExperiment_test.timepointsToProcess),true,1,false,false);
%
% % retrack
params = standard_extraction_cExperiment_parameters_default(cExperiment_test,poses);
%cExperiment.trackCells(poses,params.trackingDistance);

%extract
cExperiment_test.selectCellsToPlotAutomatic(poses,params.paramsCellSelect);
cExperiment_test.extractCellInformation(poses,false);
cExperiment_test.compileCellInformation(poses)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/traps_few_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )

%% normal timelapse edge and cente cellVision
% start at a specific seed - should lead to the same outcome every time.
rng('default')
rng(1)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_few_new_cellVision_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'few traps new cellVision';
%
l2 = load('/Users/ebakker/SkyDrive/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellMorphFiles/old_cCellMorph.mat');
cExperiment_test.cCellMorph = l2.cCellMorph;

cExperiment_test.trackTrapsInTime(poses);

cExperiment_test.RunActiveContourExperimentTracking(cExperiment_test.cCellVision,poses,min(cExperiment_test.timepointsToProcess),max(cExperiment_test.timepointsToProcess),true,1,false,false);
%
% % retrack
params = standard_extraction_cExperiment_parameters_default(cExperiment_test,poses);
%cExperiment.trackCells(poses,params.trackingDistance);

%extract
cExperiment_test.selectCellsToPlotAutomatic(poses,params.paramsCellSelect);
cExperiment_test.extractCellInformation(poses,false);
cExperiment_test.compileCellInformation(poses)
%
l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_few_new_cellVision_ref/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )


%% non trap timelapse

rng('default')
rng(1)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/no_traps_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'no traps standard';
%
l2 = load('/Users/ebakker/SkyDrive/Dropbox/MATLAB_DROPBOX/SegmentationSoftware/Matt Seg GUI/cCellMorphFiles/old_cCellMorph.mat');
cExperiment_test.cCellMorph = l2.cCellMorph;

cExperiment_test.trackTrapsInTime(poses);

cExperiment_test.RunActiveContourExperimentTracking(cExperiment_test.cCellVision,poses,min(cExperiment_test.timepointsToProcess),max(cExperiment_test.timepointsToProcess),true,1,false,false);
%
% % retrack
params = standard_extraction_cExperiment_parameters_default(cExperiment_test,poses);
%cExperiment.trackCells(poses,params.trackingDistance);

%extract
cExperiment_test.selectCellsToPlotAutomatic(poses,params.paramsCellSelect);
cExperiment_test.extractCellInformation(poses,false);
cExperiment_test.compileCellInformation(poses)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/no_traps_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )


%% more detailed tests

%% check if the centres co occur and are not simply reordering
%
% shows traps that do not match (aren't just reordering) and what the
% their centres and radii are
fprintf('\n\n starting detailed centre/size test \n\n')
total_fail = false;
for diri=1:length(cExperiment_true.dirs)
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
for tp = cTimelapse_test.timepointsToProcess
for ti = 1:length(cTimelapse_test.cTimepoint(tp).trapInfo);
    if ~isequal(cTimelapse_test.cTimepoint(tp).trapInfo(ti),cTimelapse_true.cTimepoint(tp).trapInfo(ti));
        %fprintf('timepoint %d trap %d \n',tp,ti)
        cells_c_true = [cTimelapse_true.cTimepoint(tp).trapInfo(ti).cell(:).cellCenter];
        cells_c_true = reshape(cells_c_true,2,[])';
        cells_r_true = [cTimelapse_true.cTimepoint(tp).trapInfo(ti).cell(:).cellRadius];
        cells_c_test = [cTimelapse_test.cTimepoint(tp).trapInfo(ti).cell(:).cellCenter];
        cells_c_test = reshape(cells_c_test,2,[])';
        cells_r_test = [cTimelapse_test.cTimepoint(tp).trapInfo(ti).cell(:).cellRadius];
        if ~isequal(sortrows(cells_c_test),sortrows(cells_c_true)) || ~isequal(sort(cells_r_true),sort(cells_r_test))
            fprintf('real problem :pos %d timepoint %d trap %d \n',diri,tp,ti)
            display([cells_c_true cells_r_true'])
            display([cells_c_test cells_r_test'])
            total_fail = true;
        end
    end
end
end
end
if ~total_fail, fprintf('passed detailed trapInfo centre/size test\n');end
%% check each field of extracted data and see if they are different in more than a simple reordering

fprintf('\n\n starting detailed fields test \n\n')
total_fail = false;
for diri=1:length(cExperiment_true.dirs)
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    for chi = 1:length(cTimelapse_true.extractedData)
        cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
        cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
        exD_fields = fields(cTimelapse_test.extractedData(chi));
        for fieldii = 1:length(exD_fields)
            fieldi = exD_fields{fieldii};
            if isnumeric(cTimelapse_test.extractedData(chi).(fieldi)) && (~isequal(size(cTimelapse_test.extractedData(chi).(fieldi)),size(cTimelapse_true.extractedData(chi).(fieldi)))...
                    || ~isequal(sortrows(cTimelapse_test.extractedData(chi).(fieldi)),sortrows(cTimelapse_true.extractedData(chi).(fieldi))))
                fprintf('failed at field %s , pos %d , chi %d  \n',fieldi,diri,chi)
                to_disp = sortrows(cTimelapse_test.extractedData(chi).(fieldi))-sortrows(cTimelapse_true.extractedData(chi).(fieldi));
                to_divide = sortrows(cTimelapse_true.extractedData(chi).(fieldi));
                to_divide(to_divide==0) = 1;
                display(to_disp./to_divide)
                total_fail = true;
            end
        end
    end
    
end
if ~total_fail, fprintf('passed detailed trapInfo fields test\n');end

fprintf('\n\n')


%%
clear all
close all
clc
%% test tracking and extraction on longer timelapse

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_2_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_2/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

cTimelapse = cExperiment_true.loadCurrentTimelapse(1);
cCellVision = cExperiment_true.cCellVision;

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

extractionParameters = timelapseTraps.defaultExtractParameters;
extractionParameters.channels = [5 6 7];
cExperiment_test.setExtractParameters(poses,extractionParameters);

cExperiment_test.selectTPToProcess(poses,1:50);
cExperiment_test.extractCellInformation(poses,false);

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

cExperiment_true.cTimelapse = [];
cExperiment_test.cTimelapse = [];

cExperiment_true.kill_logger = true;
cExperiment_test.kill_logger = true;

if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test\n')
else
    fprintf('\nFAILED standard processing test\n')
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'))
        
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    cTimelapse_true.ActiveContourObject = [];
    cTimelapse_test.ActiveContourObject = [];
    
    cTimelapse_true.kill_logger = true;
    cTimelapse_test.kill_logger = true;
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing test timelapse %d',diri)
    else
        fprintf('\n         FAILED standard processing test timelapse %d',diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri))
        
    end
    
end

fprintf('\n\n')

%%

clear all
close all
clc

%% test constructor.

cExperiment_test = experimentTracking('/Users/ebakker/Documents/microscope_files_swain_microscope/microscope characterisation/2015_07_07_str81_GT_segmentation/str81_GT_timelapse_01_curtailed_1-4',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_small_test');
createTimelapsePositions(cExperiment_test,'DIC','all',0.263,0,[],true);

%createTimelapsePositions(cExperiment_test);
l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_small_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

cExperiment_true.cTimelapse = [];
cExperiment_test.cTimelapse = [];

cExperiment_true.kill_logger = true;
cExperiment_test.kill_logger = true;

if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test\n')
else
    fprintf('\n             FAILED standard processing test\n')
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'))
    
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    cTimelapse_true.ActiveContourObject = [];
    cTimelapse_test.ActiveContourObject = [];
    
    cTimelapse_true.kill_logger = true;
    cTimelapse_test.kill_logger = true;
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing test timelapse %d',diri)
    else
        fprintf('\n         FAILED standard processing test timelapse %d',diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri))
        
    end
    
end

fprintf('\n\n')

%% check imsizing based on above

cTimelapse_test.imSize = [200,200];
cTimelapse_test.scaledImSize = [200,200];

if all(size(cTimelapse_test.returnSingleTimepoint(1,1))==cTimelapse_test.imSize) && ...
        all(size(cTimelapse_test.returnSingleTimepointRaw(1,1))==cTimelapse_test.rawImSize)
    
    fprintf('\n\n passed sizing test \n\n')
else
    fprintf('\n\n*** FAILED!!! sizing test ******\n\n')
    
end
%% test add secondary channel, a stack one, another, and one which does not occur

cExperiment_test = experimentTracking('/Users/ebakker/Documents/microscope_files_swain_microscope/microscope characterisation/2015_07_07_str81_GT_segmentation/str81_GT_timelapse_01_curtailed_1-4',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_addchannel_test');
createTimelapsePositions(cExperiment_test,'DIC','all',0.263,0,[],true);

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_addchannel_true/cExperiment.mat');
cExperiment_true = l2.cExperiment;
cExperiment_true.cCellVision = l2.cCellVision;

cExperiment_test.addSecondaryChannel({'GFP_001','GFP_','not found'});

cTimelapse_true = cExperiment_true.loadCurrentTimelapse(1);
cTimelapse_test = cExperiment_test.loadCurrentTimelapse(1);

cTimelapse_true.ActiveContourObject = [];
cTimelapse_test.ActiveContourObject = [];

cTimelapse_true.kill_logger = true;
cTimelapse_test.kill_logger = true;

if report_differences(cTimelapse_true,cTimelapse_test,'cTimelapse_true','cTimelapse_test');
    
    fprintf('\n\n add channel test passed \n \n')
else
    fprintf('\n\n add channel test FAILED!! \n \n')
    
end

%%
clear
close 
clc

 %% test addTimepoints
 %uses constructor test/true cExperiments 
cExperiment_test = experimentTracking('/Users/ebakker/Documents/microscope_files_swain_microscope/microscope characterisation/2015_07_07_str81_GT_segmentation/str81_GT_timelapse_01',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_test');
createTimelapsePositions(cExperiment_test,'DIC','all',0.263,0,[],true);
%createTimelapsePositions(cExperiment_test);

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_addTimepoints_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

cExperiment_test.addSecondaryChannel('GFP');
cExperiment_test.addSecondaryChannel('GFP_001');


cTimelapse_true = cExperiment_true.loadCurrentTimelapse(3);
cTimelapse_test = cExperiment_test.loadCurrentTimelapse(3);

new_first_tp = 100;

cTimelapse_test.cTimepoint((new_first_tp+1):end) = [];
cTimelapse_test.timepointsToProcess = 1:new_first_tp;
cTimelapse_test.timepointsProcessed = true(1,new_first_tp);


cTimelapse_test.addTimepoints;

cTimelapse_true.ActiveContourObject = [];
cTimelapse_test.ActiveContourObject = [];

cTimelapse_true.kill_logger = true;
cTimelapse_test.kill_logger = true;

    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed addTimepoints test timelapse')
    else
        fprintf('\n         FAILED addTimepoints test timelapse (though timepointsToProcess and timepointsProcessed are expected to be different)')
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true'),sprintf('cTimelapse_test'))
        
    end


fprintf('\n\n')

%%
clear 
close
clc

%% test continuous sementation

% Currently not used, not sure if it's worth repairing continuous
% segmentation: wouldn't be hard I guess.
 
% 
% % is sensible, this will not only have a small amount of timepoints but
% % point to a folder with a small amount of timepoints.
% l1 = load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_true/cExperiment');
% cExperiment_true = l1.cExperiment;
% cExperiment_true.cCellVision = l1.cCellVision;
% 
% report_string = ' continuous segmentation ';
% 
% cExperiment_true.copyExperiment('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_test');
% cExperiment_test = cExperiment_true;
% 
% new_tp = 2;
% for diri = 1:length(cExperiment_test.dirs)
%     cExperiment_test.loadCurrentTimelapse(diri);
%     cExperiment_test.cTimelapse.cTimepoint((new_tp+1):end) = [];
%     cExperiment_test.cTimelapse.timepointsToProcess = 1:new_tp;
%     cExperiment_test.cTimelapse.timepointsProcessed = true(1,new_tp);
%     cExperiment_test.saveTimelapseExperiment(diri);
% end
% 
% 
% l1 = load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_true/cExperiment');
% cExperiment_true = l1.cExperiment;
% cExperiment_true.cCellVision = l1.cCellVision;
% 
% 
% cExperiment_test.segmentCellsDisplayContinuous(cExperiment_test.cCellVision,1:length(cExperiment_test.dirs),max(cExperiment_true.timepointsToProcess));
% 
% if isequaln(cExperiment_test,cExperiment_true)
%     
%     fprintf('\n passed standard processing test - %s cCellVision\n',report_string)
% else
%     fprintf('\n             FAILED standard processing test - %s cCellvision\n',report_string)
%     report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'));
%     
% end
% 
% for diri=1:length(cExperiment_true.dirs)
%     
%     cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
%     cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
%     cTimelapse_true.ActiveContourObject = [];
%     cTimelapse_test.ActiveContourObject = [];
%     cTimelapse_true.kill_logger = true;
%     cTimelapse_test.kill_logger = true;
% 
%     if isequaln(cTimelapse_test,cTimelapse_true)
%         
%         fprintf('\n passed standard processing %s test timelapse %d \n',report_string,diri)
%     else
%         fprintf('\n         FAILED standard processing %s test timelapse %d \n',report_string,diri)
%         report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri));
%         
%     end
%     
% end
% 
% fprintf('\n\n')


%%

clear 
close all

%% test trap select GUI

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_select_GUI_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1;
report_string = 'trap selection GUI';

fprintf('\n\n  please remove some traps \n\n')

cExperiment_test.identifyTrapsTimelapses(1,true,true);

fprintf('\n\n  these traps should still be gone \n\n')

cExperiment_test.identifyTrapsTimelapses(1,true);

fprintf('\n\n  these traps should now be back \n\n')

cExperiment_test.identifyTrapsTimelapses(1,true,true);



%% 

cTimelapse = cExperiment_test.returnTimelapse(1);

cTimelapse.clearTrapInfo();

cTD = cTrapSelectDisplay(cTimelapse,cExperiment_test.cCellVision,[],[],[20,20,200,200]);

fprintf('\n please select some traps in the red box\n')

uiwait(cTD.figure)

fprintf('\n the traps selected should be present in this GUI \n')


cTD = cTrapSelectDisplay(cTimelapse,cExperiment_test.cCellVision,[],[],[20,20,200,200]);


%% test trapSelect Methods
l2 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_identify_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'trap identfy';

poses = 1;

cTimelapse = cExperiment_test.returnTimelapse(poses);

cTimelapse.clearTrapInfo;

cTSD = cTrapSelectDisplay(cTimelapse,cExperiment_test.cCellVision);
%close(cTDS.figure);

l2 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_identify_reference/cExperiment.mat');
cExperiment_true = l2.cExperiment;
cExperiment_true.cCellVision = l2.cCellVision;

compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )

%% test trapTracking simply

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_1_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'trap tracking simple';

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_1_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
cTimelapse.trackTrapsThroughTime;
cExperiment_test.saveTimelapseExperiment;

compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,1, report_string )


%% test trapTracking with preservation 1
% test with preservation without changing trapInfo dramatically.

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_2_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_1_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'few traps preserve 1';


cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
[cTimelapse.cTimepoint(2:end).trapInfo] = deal([]);
[cTimelapse.cTimepoint(2:end).trapInfo] = deal([]);
cTimelapse.trackTrapsThroughTime(1:100);
%cTimelapse.cTimepoint(90).trapInfo.cell = 3;
%cTimelapse.cTimepoint(100).trapInfo = [];
cTimelapse.trackTrapsThroughTime(cTimelapse.timepointsToProcess,true);

cExperiment_test.saveTimelapseExperiment;

compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,1, report_string )

%% test trapTracking with preservation 2

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_2_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_2_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'few traps preserve 2';


cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
[cTimelapse.cTimepoint(2:end).trapInfo] = deal([]);
[cTimelapse.cTimepoint(2:end).trapInfo] = deal([]);
cTimelapse.trackTrapsThroughTime(1:100);
cTimelapse.cTimepoint(90).trapInfo(1).cell = 3;
cTimelapse.cTimepoint(100).trapInfo = [];
cTimelapse.trackTrapsThroughTime(cTimelapse.timepointsToProcess,true);

cExperiment_test.saveTimelapseExperiment;

compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,1, report_string )

%% test tracking without traps

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_notraps_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'tracking no traps';

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/trap_tracking_notrap_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
[cTimelapse.cTimepoint(:).trapInfo] = deal([]);
[cTimelapse.cTimepoint(:).trapInfo] = deal([]);
cTimelapse.trackTrapsThroughTime(1:2);
cTimelapse.cTimepoint(1).trapInfo(1).cell = 3;
cTimelapse.cTimepoint(2).trapInfo = [];
cTimelapse.trackTrapsThroughTime(1:4,true);

cExperiment_test.saveTimelapseExperiment;

compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,1, report_string )


%% test ctrapDisplay GUI - in which cells are added and removed.
% check hold down t type segmentation
% check add/remove cells in full/empty traps

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'dfault classifier';

poses = 1:2;

channels_to_extract = [5 6 7];

cExperiment_test.editSegmentation(1:2,false)


%% test Tracking curation GUI

%TrackingCurator=curateCellTrackingGUI(cTimelapse,Timepoint,TrapIndex,StripWidth,Channels,ColourScheme)

%default test cExperiment.
l2 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_curateTrackingGUI_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
cTimelapse.ACParams = cExperiment_test.ActiveContourParameters;
cCellVision = cExperiment_test.cCellVision;

TrackingCurator=curateCellTrackingGUI(cTimelapse,cCellVision,1,2,7,[1 3]);


%%
clear all
close all

%% test full GUI based process.

cExpGUI = experimentTrackingGUI


%% test default extraction


l1 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/tests_cExperiment_extraction_default_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
cExperiment_test.extractCellInformation(1:2)
cExperiment_test.compileCellInformation(1:2)




%% check all possible standard extraction methods for function, though no real check on result.
l1 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/tests_cExperiment_extraction_default_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;


extractionParameters = timelapseTraps.defaultExtractParameters;

extractionParameters.functionParameters.channels = [7,8];

type = {'max','max','min','min','std','std','sum','sum'};

nuclear_channel = [8,NaN,8,NaN,8,NaN,8,NaN];

for i = 2:length(type)
    extractionParameters.functionParameters.type= type{i};
    extractionParameters.functionParameters.nuclearMarkerChannel = nuclear_channel(i);
    cExperiment_test.extractCellInformation(1:2,false,extractionParameters);
    cExperiment_test.compileCellInformation(1:2);
end



%% test missing images stuff

% copied images to my UUN directory and switch the experiment location
% between that and the local copy.

cExperiment_test = experimentTracking('/Volumes/s1135844/microscope_images/str81_GT_timelapse_01_curtailed_1-4',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/tests_cExperiment_missing_files_test');
createTimelapsePositions(cExperiment_test,{'DIC'},'all',[],0,[],60,[],true);

cExperiment_test.addSecondaryChannel('field_001');

cExperiment_test.addSecondaryChannel('GFP');

cTimelapse = cExperiment_test.loadCurrentTimelapse(1);


im1 = cTimelapse.returnSingleTimepoint(2,2,'stack');
im2 = cTimelapse.returnSingleTimepoint(2,3,'stack');


cTimelapseDisplay(cTimelapse,2)
uiwait()
cTimelapseDisplay(cTimelapse,3)
uiwait()


im1_after = cTimelapse.returnSingleTimepoint(2,2,'stack');
im2_after = cTimelapse.returnSingleTimepoint(2,3,'stack');


if ~isequal(im1,im1_after) || ~isequal(im2,im2_after)
    
    fprintf('failed changing image location test\n\n')
else
    fprintf('passedf changing image location test\n\n')

end

%% test lineage stuff

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/lineage_tracking_test/cExperiment.mat');
cExperiment = l1.cExperiment;
cExperiment.cCellVision = l1.cCellVision;

poses = 1:2;

params = standard_extraction_cExperiment_parameters_default(cExperiment,poses);


% get mother index
for diri=poses
    
    cTimelapse = cExperiment.loadCurrentTimelapse(diri);
    cTimelapse.findMotherIndex('cell_centre');
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

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/lineage_tracking_reference/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

compareExperimentTrackingObjsForTest(cExperiment,cExperiment_true,1:2, 'mother identification and lineage tracking test: ' )

%% special slide GUI

% special GUI written for Ivan to extract data from slides.

cExpGUI = experimentTrackingSlidesGUI;

%% test cell outline editing GUI

small_im = cTimelapse.returnSingleTrapTimepoint(1,1);
edit ACBackGroundFunctions.edit_AC_manual_TEST
