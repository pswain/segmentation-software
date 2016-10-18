function editSegmentationGUI(cExpGUI)
% editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap,pos_traps_to_show,channel)
%
%
% cExperiment             :   object of the experimentTracking class
% cCellVision             :   object of the cellVision class
% positionsToIdentify     :   array of indices position to show. Defaults
%                             to all in cExperiment
% show_overlap            :   logical of whether to show tracking. asks via
%                             GUI if not provided.
% pos_traps_to_show       :   cell array of traps to show at each position
%                             (an array of trap indices for each position
%                             stored in a cell array). Defaults to showing
%                             all traps for each position.
% channel                 :   channel from which to take underlying image.
%                             defaults to 1.
%
% This opens the cTrapDisplay GUI for each position requested, which is the
% GUI used for editing segmentation result by addition and removal of
% cells. 
%
% the GUI's are opened in turn, with each being opened after the present
% one is closed.


cExperiment = cExpGUI.cExperiment;
cCellVision = cExpGUI.cExperiment.cCellVision;
positionsToIdentify = get(cExpGUI.posList,'Value');
pos_traps_to_show = [];
channel= 1;
pos_traps_to_show_given = false;


if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
end

    
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    cTimelapse=loadCurrentTimelapse(cExperiment,currentPos);
    
    
    if isempty(cTimelapse.ActiveContourObject)
        cTimelapse.InstantiateActiveContourTimelapseTraps(cExperiment.ActiveContourParameters);
    else
        cTimelapse.ActiveContourObject.TimelapseTraps = cTimelapse;
        %necessary to make sure that a loaded cTimelapse in the ActiveContourObject points to the
        %right place.
    end
    
    if i==1
        
        % if channel field is empty, get user to select a channel
        % bit laborious but resilient to people putting the wrong numbers
        % in the boxes (i.e. only cares about sign).
        while isempty(cExperiment.ActiveContourParameters.ImageTransformation.channel)
            prompts = cTimelapse.channelNames;
            prompts{1} = sprintf(['The image used for the active contour method is constructed by'...
                ' the addition and subtraction of channels, and should be constructed such that '...
                'cell edges are regions that go from bright to dark moving out from the cell.\n'...
                'Please select channels such that this is so but putting a 1 in channels that '...
                'should be contributed positively and -1 for thos that should contribute negatively. leave all others blank.\n'...
                'If you are unsure, but a 1 in DIC/birghtfield_001 and a -1 in DIC/Brightfield_003 \n \n %s'...
                ],prompts{1});
            answer = inputdlg(prompts,'select active contour channels',1);
            if isempty(answer)
                fprintf('\n\n   Active contour method cancelled\n\n')
                return
            else
            answer = answer';
            answer_array = sign(cellfun(@(x) str2double(x),answer,'UniformOutput',true));
            channels_to_use = find(~isnan(answer_array));
            cExperiment.ActiveContourParameters.ImageTransformation.channel = channels_to_use.*answer_array(channels_to_use);
            cExperiment.ActiveContourParameters.ActiveContour.ShowChannel = 1;
            end
        end
        
    end
    
    cTimelapse.ActiveContourObject.Parameters = cExperiment.ActiveContourParameters;

    curateCellTrackingGUI(cTimelapse,cExperiment.cCellVision,1,1,1,1);
    uiwait();
    
    % set the timepoints to be processed to be true so that it will be
    % extracted.
    cTimelapse.timepointsProcessed = true;
    
    % set all cells to be extracted
    cTimelapse.cellsToPlot = sparse(true(1,cTimelapse.returnMaxCellLabel(1)));
    
    cExperiment.posSegmented(currentPos)=1;
    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
