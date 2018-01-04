function editSegmentationGUI(cExpGUI)
% editSegmentationGUI(cExpGUI)
%
% This opens the curateCellTrackingGUI GUI for each position requested.
% This is the GUI accessed by holding down T and clicking on a cell in the
% normal GUI (cells are yellow and blue), as oppose the the cTrapDisplay
% GUI opened in the conventional experimentTrackingGUI.
% This GUI can add/remove cells and change the outline. See it's help for
% further information.
%   
% the GUI's are opened in turn, with each being opened after the present
% one is closed.
%
% See Also curateCellTrackingGUI
           
cExperiment = cExpGUI.cExperiment;
positionsToIdentify = get(cExpGUI.posList,'Value');


if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
end

    
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    cTimelapse=loadCurrentTimelapse(cExperiment,currentPos);
    
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
    
    cTimelapse.ACParams = cExperiment.ActiveContourParameters;

    curateCellTrackingGUI(cTimelapse,1,1,1,1);
    uiwait();
    
    % set the timepoints to be processed to be true so that it will be
    % extracted.
    cTimelapse.timepointsProcessed = true;
    
    % set all cells to be extracted
    cTimelapse.cellsToPlot = sparse(true(1,cTimelapse.returnMaxCellLabel(1)));
    
    cExperiment.posSegmented(currentPos)=1;
    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment;
end
