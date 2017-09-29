function RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged,CellsToUse)
%RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged,CellsToUse)
%runs one of a variety of active contour methods on the positions selected. Parameters must be
%changed before execution if non standard parameters are desired.
%OverwriteTimelapseParameters controls if experiment or timelapse parameters are used
%ACmethods specifies which particular method to use.
%
%cExperiment                        - experimentTracking object
%cCellVision                        - cCellVision object
%positionsToIdentify                - positions to use
%FirstTimepoint                     - time point to start segmenting
%LastTimepoint                      - time point to stop segmenting
%OverwriteTimelapseParameters       - whether to overwrite the cTimelapse
%                                     parameters with cExperiment
%                                     parameters
%ACmethod                           - which method to use (chosen by dialog)
%TrackTrapsInTime                   - whether to track the traps first
%LeaveFirstTimepointUnchanged       - boolean. whether to leave the outline
%                                     of the first time point fixed.
%CellsToUse                         - a cell array of CellToUse matrices
%                                     for each position (so should include
%                                     empty entries for positions not to
%                                     segment. If it is empty it will do
%                                     all the cells.


if nargin<3 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

LowestAllowedTimepoint = min(cExperiment.timepointsToProcess(:));
LowestAllowedTimepoint = max([LowestAllowedTimepoint;1]);
HighestAllowedTimepoint = max(cExperiment.timepointsToProcess(:));
HighestAllowedTimepoint = min([HighestAllowedTimepoint;cExperiment.timepointsToLoad]);

if nargin <5 || (isempty(FirstTimepoint) || isempty(LastTimepoint))
    answer = inputdlg(...
        {'Enter the timepoint at which to begin the active contour method' ;'Enter the timepoint at which to stop'},...
        'start and end times of active contour method',...
        1,...
        {int2str(LowestAllowedTimepoint); int2str(HighestAllowedTimepoint)});
    
    if isempty(answer)
        fprintf('\n\n active contour method cancelled\n\n');
        return
    end
    FirstTimepoint = str2num(answer{1});
    LastTimepoint = str2num(answer{2});
  
end

if FirstTimepoint<LowestAllowedTimepoint
    FirstTimepoint = LowestAllowedTimepoint;
end

if LastTimepoint>HighestAllowedTimepoint
    LastTimepoint = HighestAllowedTimepoint;
end


if nargin<6 || isempty(OverwriteTimelapseParameters)
    OverwriteTimelapseParameters = true;                      
end


if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTraps.LoadDefaultParameters; 
end

if isempty(cExperiment.cCellMorph)
    cExperiment.cCellMorph = experimentTracking.loadDefaultCellMorphologyModel; 
end

if nargin<8 ||isempty(TrackTrapsInTime)
    
    options = {'track traps in time' 'don''t'};
    cancel_option = 'cancel';
   button_answer = questdlg('Would you like to track the traps through time - necessary if not done already', ...
                         'track in time:', ...
                         options{1},options{2},cancel_option,options{1});
                     
     if strcmp(button_answer,cancel_option)
         fprintf('\n\n    active contour method cancelled    \n\n')
         return
     elseif strcmp(button_answer,options{1})
         TrackTrapsInTime = true;
     elseif strcmp(button_answer,options{2})
         TrackTrapsInTime = false;
     end
    
end

if nargin<9 || isempty(LeaveFirstTimepointUnchanged)
    
    LeaveFirstTimepointUnchanged = false;
     
end

if nargin<10 || isempty(CellsToUse)
    
    CellsToUse = cell(size(cExperiment.dirs));
    [CellsToUse{:}] = deal([]);
    
end

% Load the first cTimelapse:
cTimelapse = cExperiment.loadCurrentTimelapse(positionsToIdentify(1));

% If channel field is empty, get user to select a channel
% bit laborious but resilient to people putting the wrong numbers
% in the boxes (i.e. only cares about sign).
while isempty(cExperiment.ActiveContourParameters.ImageTransformation.channel) && ~cExperiment.ActiveContourParameters.ImageTransformation.EdgeFromDecisionImage
    prompts = cTimelapse.channelNames;
    prompts{1} = sprintf(['The image used for the active contour method is constructed by'...
        ' the addition and subtraction of channels, and should be constructed such that '...
        'cell edges are regions that go from bright to dark moving out from the cell.\n'...
        'Please select channels such that this is so but putting a 1 in channels that '...
        'should be contributed positively and -1 for thos that should contribute negatively. leave all others blank.\n'...
        'If you are unsure, but a 1 in DIC/Brightfield_001 and a -1 in DIC/Brightfield_003 \n \n %s'...
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
            
% Start logging protocol
cExperiment.logger.add_arg('TrackTrapsInTime',TrackTrapsInTime);
cExperiment.logger.add_arg('ActiveContourParameters',cExperiment.ActiveContourParameters);
cExperiment.logger.start_protocol('active contour segmentation',length(positionsToIdentify));
% The first timelapse is pre-loaded, so trigger a PositionChanged event to 
% notify experimentLogging:
experimentLogging.changePos(cExperiment,positionsToIdentify(1),cTimelapse);

% default AC params for parsing
DefaultParameters = timelapseTraps.LoadDefaultACParams; 


% undo comments - just to debug
%try
    %% Load timelapses
    for i=1:length(positionsToIdentify)
        currentPos=positionsToIdentify(i);
        
        if i~=1
            cTimelapse = cExperiment.loadCurrentTimelapse(currentPos);
        end
        
        if TrackTrapsInTime
            cExperiment.cTimelapse.trackTrapsThroughTime(cExperiment.timepointsToProcess);
            cExperiment.saveTimelapseExperiment(currentPos);
            cExperiment.cTimelapse = cTimelapse;
            
        end
        
        if OverwriteTimelapseParameters
            cTimelapse.ACParams = cExperiment.ActiveContourParameters;
        end
        
        % parse parameters so that anything that has a default value will have
        % some value.
        fields = fieldnames(DefaultParameters);
        for fi = 1:length(fields)
            cTimelapse.ACParams.(fields{fi}) = parse_struct(...
                cTimelapse.ACParams.(fields{fi}),...
                DefaultParameters.(fields{fi}) );
        end
    
        % undo - just for debugging
        %try
            cTimelapse.segmentACexperimental(cExperiment.cCellVision,cExperiment.cCellMorph,FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,CellsToUse{currentPos});
        %catch err
        %    rethrow(err)
        %end
        cExperiment.saveTimelapseExperiment(currentPos);
        
        
        disp.cExperiment.posSegmented(currentPos) = true;
        disp.cExperiment.posTracked(currentPos) = true;
    end
    
    % Finish logging protocol
    cExperiment.logger.complete_protocol;
%catch err
%    cExperiment.logger.protocol_error;
%    rethrow(err);
%end

fprintf(['finished running active contour method on experiment ' datestr(now) ' \n \n'])

beep;pause(0.3);beep

end

