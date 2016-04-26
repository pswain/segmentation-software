function exportTrapImages(cExperiment,positions,export_directory,root_name,timepoints,channels,do_TrapImage,do_SegmentationResult,do_DecisionImage)
% exportTrapImages(cExperiment,positions,export_directory,root_name,timepoints,channels,do_TrapImage,do_SegmentationResult,do_DecisionImage)
%
% exports trap images for each position in pos to a different directory. 

if nargin<2 || isempty(positions)
    positions = 1:length(cExperiment.dirs);
end

if nargin<3 || isempty(export_directory)
    export_directory = uigetdir([],'please select directory to which to export');
end

if nargin<4 || isempty(root_name)
    default_answer = strfind(cExperiment.rootFolder,filesep);
    default_answer = cExperiment.rootFolder((default_answer(end)+1):end);
    root_name = inputdlg({'please enter the root name for export'},'root name',1,{default_answer});
    root_name = root_name{1};
end

if nargin<5 || isempty(timepoints)
    timepoints = cExperiment.timepointsToProcess;
end

if nargin<6|| isempty(channels)
    cTimelapse = cExperiment.loadCurrentTimelapse(positions(1));
    [channels,ok_response] = cTimelapse.selectChannelGUI('select channel','please select channels to export',true);
    if ~ok_response
        fprintf('\n\n       image export aborted \n\n')
        return
    end
end

if nargin<9 
    answer = settingsdlg('title','other option',...
        'description','please select whether to export other options',...
        {'trap pixels';'do_Trap'},true,...
        {'segmentation result';'do_SegRes'},true,...
        {'decision image (VERY slow)';'do_DIM'},false...
        );
do_TrapImage = answer.do_Trap;
do_SegmentationResult = answer.do_SegRes;
do_DecisionImage = answer.do_DIM;
end

%do export

for posi = 1:length(positions)
    pos = positions(posi);
    cTimelapse = cExperiment.loadCurrentTimelapse(pos);
    cT_export_directory = fullfile(export_directory,cExperiment.dirs{pos});
    if ~isdir(cT_export_directory)
        mkdir(export_directory,cExperiment.dirs{pos});
    end
    exportTrapImage(cTimelapse,cT_export_directory,[root_name '_' cExperiment.dirs{pos}],[],timepoints,channels,do_TrapImage,do_SegmentationResult,cExperiment.cCellVision,do_DecisionImage);

end


end