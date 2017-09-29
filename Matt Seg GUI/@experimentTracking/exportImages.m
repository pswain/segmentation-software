function exportImages(cExperiment,positions,export_directory,root_name,timepoints,channels,do_traps,do_TrapImage,do_SegmentationResult,do_DecisionImage,change_file_locations)
% exportImages(cExperiment,positions,export_directory,root_name,timepoints,channels,do_traps,do_TrapImage,do_SegmentationResult,do_DecisionImage,change_file_locations)
%
% exports images for each position in pos to a different directory. 
% if do_traps, does each trap individually to a new directory.
% if do_traps, has other options (like decisionImage, SegmentationResult
% etc.)

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
% if do traps
if nargin<7 || isempty(do_traps)
    bt1 = 'traps';
    trap_or_whole = questdlg('Do you wish to export trap images or whole image','traps or whole?',bt1,'whole images','traps');
    do_traps = strcmp(trap_or_whole,bt1);
end

% set other parameters
if nargin<10 && do_traps
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

if nargin <11 && ~do_traps
    bt1 = 'yes';
    change_loc = questdlg('Do you wish to change file locations to point at these images','change file locaitons?',bt1,'No',bt1);
    change_file_locations = strcmp(change_loc,bt1);
end

%do export

for posi = 1:length(positions)
    pos = positions(posi);
    cTimelapse = cExperiment.loadCurrentTimelapse(pos);
    cT_export_directory = fullfile(export_directory,cExperiment.dirs{pos});
    if ~isdir(cT_export_directory)
        mkdir(export_directory,cExperiment.dirs{pos});
    end
    if do_traps
        exportTrapImage(cTimelapse,cT_export_directory,[root_name '_' cExperiment.dirs{pos}],[],timepoints,channels,do_TrapImage,do_SegmentationResult,cExperiment.cCellVision,do_DecisionImage);
    else
        name = [root_name '_' cExperiment.dirs{pos}];
        fprintf('position %d : %d timepoints \n',posi,length(timepoints))
        for tp = timepoints
            for ch = channels
                im = cTimelapse.returnSingleTimepoint(tp,ch);
                im_towrite = uint16(im);
                im_name = sprintf('%s%s%s_tp%0.6d_%s.png',cT_export_directory,filesep,name,tp,cTimelapse.channelNames{ch});
                imwrite(im_towrite,im_name);
                if change_file_locations
                    cTimelapse.cTimepoint(tp).filename{ch} = im_name;
                end
            end
            PrintReportString(tp,50)
        end
        if change_file_locations
            cTimelapse.timelapseDir = 'ignore';
            cExperiment.saveTimelapse(pos);
        end
    end
end

fprintf('\n\ndone\n\n')
end