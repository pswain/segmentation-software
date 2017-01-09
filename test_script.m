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

%% non trap timelapse

rng('default')
rng(1)

l1 = load('/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/no_traps_test/cExperiment.mat');
cExperiment_test = l1.cExperiment;
cExperiment_test.cCellVision = l1.cCellVision;
poses = 1:2;
report_string = 'no traps standard';
%

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

cExperiment_true.logger = [];
cExperiment_test.logger = [];

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
    
    cTimelapse_true.logger = [];
    cTimelapse_test.logger = [];
    
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
    '/Users/ebakker/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_test');
createTimelapsePositions(cExperiment_test,{'DIC'},'all',[],0,[],60,[],true);

%createTimelapsePositions(cExperiment_test);
l1 =  load('~/Documents/microscope_files_swain_microscope_analysis/tests/test_cExperiment_constructor_true/cExperiment.mat');
cExperiment_true = l1.cExperiment;
cExperiment_true.cCellVision = l1.cCellVision;

cExperiment_true.cTimelapse = [];
cExperiment_test.cTimelapse = [];

cExperiment_true.logger = [];
cExperiment_test.logger = [];

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
    
    cTimelapse_true.logger = [];
    cTimelapse_test.logger = [];
    
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

cTimelapse_true.ActiveContourObject = [];
    cTimelapse_test.ActiveContourObject = [];
    
    cTimelapse_true.logger = [];
    cTimelapse_test.logger = [];

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

cTimelapse_true.ActiveContourObject = [];
cTimelapse_test.ActiveContourObject = [];

cTimelapse_true.logger = [];
cTimelapse_test.logger = [];

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
%     cTimelapse_true.logger = [];
%     cTimelapse_test.logger = [];
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

TrackingCurator=curateCellTrackingGUI(cTimelapse,cCellVision,1,2,7,[1 3]);



%% test full GUI based process.

disp = experimentTrackingGUI


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

%% special slide GUI

% special GUI written for Ivan to extract data from slides.

cExpGUI = experimentTrackingSlidesGUI;
