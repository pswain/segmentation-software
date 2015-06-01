function RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged)
%RunActiveContourExperimentTracking(cExperiment,cCellVision,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters,ACmethod,TrackTrapsInTime,LeaveFirstTimepointUnchanged)
%runs one of a variety of active contour methods on the positions selected. Parameters must be
%changed before execution if non standard parameters are desired.
%OverwriteTimelapseParameters controls if experiment or timelapse parameters are used
%ACmethods specifies which particular method to use.


if nargin<2 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

LowestAllowedTimepoint = min(cExperiment.timepointsToProcess(:));
LowestAllowedTimepoint = max([LowestAllowedTimepoint;1]);
HighestAllowedTimepoint = max(cExperiment.timepointsToProcess(:));
HighestAllowedTimepoint = min([HighestAllowedTimepoint;cExperiment.timepointsToLoad]);

if nargin <4 || (isempty(FirstTimepoint) || isempty(LastTimepoint))
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


if nargin<5 || isempty(OverwriteTimelapseParameters)
    options = {'overwrite' 'keep individiual parameter sets'};
    cancel_option = 'cancel';
   button_answer = questdlg('Would you like to overwrite the individual timelapse parameters with the cExperiment active contour parameters? Unless you know a reason why, you probably want to choose ''overwrite'' ', ...
                         'overwrite:', ...
                         options{1},options{2},cancel_option,options{1});
                     
     if strcmp(button_answer,cancel_option)
         fprintf('\n\n    active contour method cancelled    \n\n')
         return
     elseif strcmp(button_answer,options{1})
         OverwriteTimelapseParameters = true;
     elseif strcmp(button_answer,options{2})
         OverwriteTimelapseParameters = false;
     end
                     
                     
                     
end


if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
end

if nargin<7 ||isempty(TrackTrapsInTime)
    
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

if nargin<8 || isempty(LeaveFirstTimepointUnchanged)
   options = {'leave unchanged' 'change'};
    cancel_option = 'cancel';
   button_answer = questdlg('Would you like to leave the first timepoint unchanged?', ...
                         'leave first timepoint unchanged:', ...
                         options{1},options{2},cancel_option,options{1});
                     
     if strcmp(button_answer,cancel_option)
         fprintf('\n\n    active contour method cancelled    \n\n')
         return
     elseif strcmp(button_answer,options{1})
         LeaveFirstTimepointUnchanged = true;
     elseif strcmp(button_answer,options{2})
         LeaveFirstTimepointUnchanged = false;
     end
    
end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load(fullfile(cExperiment.saveFolder,[ cExperiment.dirs{currentPos} 'cTimelapse']),'cTimelapse');
    cExperiment.cTimelapse=cTimelapse;
    
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
    end
    
    
    
    if method_dialog_answer_value == false;
        fprintf('\n\n   Active contour method cancelled\n\n')
        return
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
    
    cTimelapse.RunActiveContourTimelapseTraps(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,ACmethod);
    
    cExperiment.saveTimelapseExperiment(currentPos);
    
    fprintf('finished position %d of %d \n \n',i,length(positionsToIdentify))
    
    disp.cExperiment.posSegmented(currentPos) = true;
    disp.cExperiment.posTracked(currentPos) = true;
end

fprintf(['finished running active contour method on experiment ' datestr(now) ' \n \n'])

beep;pause(0.3);beep

end

