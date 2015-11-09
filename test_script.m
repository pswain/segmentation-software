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



%%
clc
clear all
close all

%% load  twostage default classifier
l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'dfault classifier';

poses = 1:2;

channels_to_extract = [5 6 7];

%% load  wholTrap cCellVision type

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_wholeTrapIm_cCellVision_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_wholeTrapIm_cCellVision_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'wholeTrap classifier';

poses = 1:2;

channels_to_extract = [5 6 7];

%% load  wholIm cCellVision type

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_wholeIm_cCellVision_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_wholeIm_cCellVision_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'wholeIm classifier';

poses = 1:2;

channels_to_extract = [5 6 7];

%% load  no traps  cExperiments

l1 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_notrap_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_notrap_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'no traps';

poses = 1:2;

channels_to_extract = [4];


%%

cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
cCellVision = cExperiment_test.cCellVision;


%% test cell identification, tracking and identification on very short timelapse
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

cExperiment_test.extractCellInformation(poses,'max',channels_to_extract);

cExperiment_test.compileCellInformation(poses);


if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test - %s cCellVision\n',report_string)
else
    fprintf('\n             FAILED standard processing test - %s cCellvision\n',report_string)
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'));
    
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    cTimelapse_true.ActiveContourObject = [];
    cTimelapse_test.ActiveContourObject = [];
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing %s test timelapse %d \n',report_string,diri)
    else
        fprintf('\n         FAILED standard processing %s test timelapse %d \n',report_string,diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri));
        
    end
    
end

fprintf('\n\n')

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
            if ~isequal(size(cTimelapse_test.extractedData(chi).(fieldi)),size(cTimelapse_true.extractedData(chi).(fieldi)))...
                    || ~isequal(sortrows(cTimelapse_test.extractedData(chi).(fieldi)),sortrows(cTimelapse_true.extractedData(chi).(fieldi)))
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

%%

clear all
close all
clc

%% test constructor.

cExperiment_test = experimentTracking('/Users/ebakker/Documents/microscope_files_swain_microscope/microscope characterisation/2015_07_07_str81_GT_segmentation/str81_GT_timelapse_01',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_test');
createTimelapsePositions(cExperiment_test,{'DIC'},'all',[],0,[]);
%createTimelapsePositions(cExperiment_test);

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


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


%% test add secondary channel

l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_addchannel_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_addchannel_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

cTimelapse_true = cExperiment_true.loadCurrentTimelapse(1);
cTimelapse_test = cExperiment_test.loadCurrentTimelapse(1);

cTimelapse_test.addSecondaryTimelapseChannel('GFP_001');

if report_differences(cTimelapse_true,cTimelapse_test);
    
    fprintf('\n\n add channel test passed \n \n')
    
end
%%
clear
close 
clc

 %% test addTimepoints
 %uses constructor test/true cExperiments 
cExperiment_test = experimentTracking('/Users/ebakker/Documents/microscope_files_swain_microscope/microscope characterisation/2015_07_07_str81_GT_segmentation/str81_GT_timelapse_01',...
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_test');
createTimelapsePositions(cExperiment_test,{'DIC'},'all',[],0,[]);
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


    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed addTimepoints test timelapse')
    else
        fprintf('\n         FAILED addTimepoints test timelapse')
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true'),sprintf('cTimelapse_test'))
        
    end


fprintf('\n\n')

%%
clear 
close
clc

%% test continuous sementation

% is sensible, this will not only have a small amount of timepoints but
% point to a folder with a small amount of timepoints.
l1 = load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_true/cExperiment');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

report_string = ' continuous segmentation ';

cExperiment_true.copyExperiment('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_test');
cExperiment_test = cExperiment_true;

new_tp = 2;
for diri = 1:length(cExperiment_test.dirs)
    cExperiment_test.loadCurrentTimelapse(diri);
    cExperiment_test.cTimelapse.cTimepoint((new_tp+1):end) = [];
    cExperiment_test.cTimelapse.timepointsToProcess = 1:new_tp;
    cExperiment_test.cTimelapse.timepointsProcessed = true(1,new_tp);
    cExperiment_test.saveTimelapseExperiment(diri);
end


l1 = load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_continuousSegment_true/cExperiment');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;


cExperiment_test.segmentCellsDisplayContinuous(cExperiment_test.cCellVision,1:length(cExperiment_test.dirs),max(cExperiment_true.timepointsToProcess));

if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n passed standard processing test - %s cCellVision\n',report_string)
else
    fprintf('\n             FAILED standard processing test - %s cCellvision\n',report_string)
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'));
    
end

for diri=1:length(cExperiment_true.dirs)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n passed standard processing %s test timelapse %d \n',report_string,diri)
    else
        fprintf('\n         FAILED standard processing %s test timelapse %d \n',report_string,diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri));
        
    end
    
end

fprintf('\n\n')


%%

clear 
close all

%% test ctrapDisplay GUI - in which cells are added and removed.
% check hold down t type segmentation
% check add/remove cells in full/empty traps

l2 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_1/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

report_string = 'dfault classifier';

poses = 1:2;

channels_to_extract = [5 6 7];

cExperiment_test.editSegmentation(cExperiment_test.cCellVision,1:2,false)


%% test Tracking curation GUI

%TrackingCurator=curateCellTrackingGUI(cTimelapse,Timepoint,TrapIndex,StripWidth,Channels,ColourScheme)

%default test cExperiment.
l2 =  load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_curateTrackingGUI_test/cExperiment.mat');
cExperiment_test = l2.cExperiment;
cExperiment_test.cCellVision = l2.cCellVision;

cTimelapse = cExperiment_test.loadCurrentTimelapse(1);
cCellVision = cExperiment_test.cCellVision;

TrackingCurator=curateCellTrackingGUI(cTimelapse,1,2,7,[1 3]);



%% test full GUI based process.

disp = experimentTrackingGUI



