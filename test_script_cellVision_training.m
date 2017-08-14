%%%%%%%% test script for cellVision training %%%%%%%%%%%%%%%%%


% simple debug for cellVision script. Some of the main functions with non
% obvious effects.

%% generate training set
% start at a specific seed - should lead to the same outcome every time.
rng('default')
rng(1)
load('~/Documents/microscope_files_swain_microscope_analysis/tests/cellVision_generate_test.mat')
step_size=59;

% this should be left true so that outputs can be inspected.
debugging = true; 

debug_outputs  =  cCellVision.generateTrainingSetTimelapseCellEdge(cTimelapse,step_size,SegMethod,debugging);

fprintf('\n  training set obtained \n')

l_ref = load('~/Documents/microscope_files_swain_microscope_analysis/tests/cellVision_generate_ref.mat');
%
fail = false;
if ~isequaln(l_ref.debug_outputs,debug_outputs)
    fprintf('\n\n failed debug outputs\n\n')
    fail = true;
end
if ~report_differences(cCellVision,l_ref.cCellVision,'ref_cellVision','test_cellVision')
    fprintf('\n\nfailed cellVision comparison\n\n')
    fail = true;
end    

if ~fail
    fprintf('\n\n passed generation test \n\n')
end




