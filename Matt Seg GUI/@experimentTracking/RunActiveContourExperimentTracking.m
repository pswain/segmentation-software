function RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged,CellsToUse)
%RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged)
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

%fairly pointless GUI
%
%     options = {'overwrite' 'keep individiual parameter sets'};
%     cancel_option = 'cancel';
%    button_answer = questdlg('Would you like to overwrite the individual timelapse parameters with the cExperiment active contour parameters? Unless you know a reason why, you probably want to choose ''overwrite'' ', ...
%                          'overwrite:', ...
%                          options{1},options{2},cancel_option,options{1});
%                      
%      if strcmp(button_answer,cancel_option)
%          fprintf('\n\n    active contour method cancelled    \n\n')
%          return
%      elseif strcmp(button_answer,options{1})
%          OverwriteTimelapseParameters = true;
%      elseif strcmp(button_answer,options{2})
%          OverwriteTimelapseParameters = false;
%      end
                     
                     
end


if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
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
    
% another fairly pointless user interface
% 
%    options = {'leave unchanged' 'change'};
%     cancel_option = 'cancel';
%    button_answer = questdlg('Would you like to leave the first timepoint unchanged?', ...
%                          'leave first timepoint unchanged:', ...
%                          options{1},options{2},cancel_option,options{1});
%                      
%      if strcmp(button_answer,cancel_option)
%          fprintf('\n\n    active contour method cancelled    \n\n')
%          return
%      elseif strcmp(button_answer,options{1})
%          LeaveFirstTimepointUnchanged = true;
%      elseif strcmp(button_answer,options{2})
%          LeaveFirstTimepointUnchanged = false;
%      end
%     
end

if nargin<10 || isempty(CellsToUse)
    
    CellsToUse = cell(size(cExperiment.dirs));
    [CellsToUse{:}] = deal([]);
    
end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    
    cTimelapse = cExperiment.loadCurrentTimelapse(currentPos);
    
    if isempty(cTimelapse.ActiveContourObject)
        cTimelapse.InstantiateActiveContourTimelapseTraps(cExperiment.ActiveContourParameters);
    else
        cTimelapse.ActiveContourObject.TimelapseTraps = cTimelapse;
        %necessary to make sure that a loaded cTimelapse in the ActiveContourObject points to the
        %right place.
    end
    
    if i==1
        
        if nargin<6 || isempty(ACmethod)
            [ACmethod,method_dialog_answer_value] = cTimelapse.ActiveContourObject.SelectACMethod;
        else
            [ACmethod,method_dialog_answer_value] = cTimelapse.ActiveContourObject.SelectACMethod(ACmethod);
        end
        
        if method_dialog_answer_value == false;
            fprintf('\n\n   Active contour method cancelled\n\n')
            return
        end
        
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
            end
        end
        
    end
    
    if TrackTrapsInTime
        cExperiment.cTimelapse.trackTrapsThroughTime(cCellVision,cExperiment.timepointsToProcess);
        cExperiment.saveTimelapseExperiment(currentPos);
        cExperiment.cTimelapse = cTimelapse;
        
    end
    
    if OverwriteTimelapseParameters
        cTimelapse.ActiveContourObject.Parameters = cExperiment.ActiveContourParameters;
    end
    
    %on the first position find the trap images and then just assign all the relevant fields for
    %other positions.
    if  (cTimelapse.ActiveContourObject.TrapPresentBoolean && (OverwriteTimelapseParameters || isempty(cTimelapse.ActiveContourObject.TrapPixelImage))) || isempty(cTimelapse.ActiveContourObject.cCellVision)
            getTrapInfoFromCellVision(cTimelapse.ActiveContourObject,cCellVision);
    end
    
    if isempty(cTimelapse.ActiveContourObject.TrapLocation) || OverwriteTimelapseParameters
        cTimelapse.ActiveContourObject.getTrapLocationsFromCellVision;
    end
    
    cTimelapse.RunActiveContourTimelapseTraps(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,ACmethod,CellsToUse{currentPos});
    
    cExperiment.saveTimelapseExperiment(currentPos);
    
    fprintf('finished position %d.  %d of %d \n \n',currentPos,i,length(positionsToIdentify))
    
    disp.cExperiment.posSegmented(currentPos) = true;
    disp.cExperiment.posTracked(currentPos) = true;
end

fprintf(['finished running active contour method on experiment ' datestr(now) ' \n \n'])

beep;pause(0.3);beep

end

