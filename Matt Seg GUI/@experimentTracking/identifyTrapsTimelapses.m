function identifyTrapsTimelapses(cExperiment,positionsToIdentify,TrackFirstTimepoint,ClearTrapInfo)
% identifyTrapsTimelapses(cExperiment,positionsToIdentify,TrackFirstTimepoint,ClearTrapInfo)
%
%method to select the traps in a collection of positions. Runs through the
%positions selected opening each in a cTrapSelectDisplay GUI and saving the
%result.
%
% TrackFirstTimpoint :  boolean. If true it tracks the first position after
%                       selection and uses the result to rule out positions
%                       that drift out of the field of view in the
%                       subsequent timepoints. Then need to reselect first
%                       position.
%
% ClearTrapInfo      :  boolean . if true
%                       clears all the previous trapInfo other than
%                       fielnames. 
%                       If false it doesn't clear the
%                       trapInfo. 
%                       If left empty it defaults to the hidden variable
%                       EXPERIMENTTRACKING.CLEAROLDTRAPINFO 
%                       A housekeeping variable that tells the software to
%                       clear the trapInfo when appropriate: when changing
%                       cCellVision models for example.
%
% See also, CTRAPSELECTDISPLAY

if nargin<2 ||isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(TrackFirstTimepoint)
    
    
    
    Message=(['Each position of the experiment will be displayed one by one in two GUIs: one to select traps and one that allows you to scroll through the image and channels.'...
        ' The program will guess where the traps are present at first, but you will need to add (left-click) or remove' ...
        ' (right-click) traps to make sure that the trap selection is properly performed. It is generally advisable to look at the timelapse for a single position to make sure the stage ' ...
        'didnt drift too much during the experiment. If it did drift you want to make sure not to select traps that will go out of the field of view during the experiment.']);
    h = helpdlg(Message);
    uiwait(h);
    
    Positive ='track first timepoint' ;
    Negative ='no thanks' ;
    TrackFirstTimpointDlgOut = questdlg(...
        {['Would you like to track the first timepoint to find drift and use this to try and rule out'...
        ' traps that will be lost due to drift? This will delete any cell information in the first timepoint'...
        ' submitted.This is only useful if selecting traps in numerous positions and if the experiment has a'...
        ' reasonably large drift and if you only want analyse positions present for the whole duration.'],...
        '',...
        ['in any case, regions in which the software is not automatically detecting traps, for drift or '...
        'because they are too close to the edge are shown as red boxes.']}...
        ,'track first timepoint to remove drift?',Positive,Negative,Negative);
    
    TrackFirstTimepoint = strcmp(TrackFirstTimpointDlgOut,Positive);
    
end

if nargin<4 || isempty(ClearTrapInfo) 
    ClearTrapInfo = cExperiment.clearOldTrapInfo;
elseif all(ClearTrapInfo)
    ClearTrapInfo = true(size(positionsToIdentify));
elseif  all(~(ClearTrapInfo))
    ClearTrapInfo = false(size(positionsToIdentify));
end

% Start logging protocol
cExperiment.logger.start_protocol('selecting traps',length(positionsToIdentify));


try
    
    for i=1:length(positionsToIdentify)
        currentPos=positionsToIdentify(i);
        
        % if there are not traps and not clearing trapInfo, don't bother to
        % load and go to the next iteration of the for loop
        if ~(cExperiment.trapsPresent || any(clearTrapInfo))
            continue
        end
        
        cTimelapse=cExperiment.loadCurrentTimelapse(currentPos);
        
        if i==1
            % define ExclusionZone with which to exclude traps more than on quarter
            % out of image. at the first timpoint processed.
            y_bound = round(cTimelapse.trapImSize(1)/4);
            x_bound = round(cTimelapse.trapImSize(2)/4);
            ExclusionZone = [1, 1, cTimelapse.imSize(2) - 1, y_bound;...
                1, 1,  x_bound, cTimelapse.imSize(1) - 1;...
                (cTimelapse.imSize(2) - x_bound), 1, x_bound - 1, cTimelapse.imSize(1) - 1;...
                1, (cTimelapse.imSize(1) - y_bound), cTimelapse.imSize(2) - 1, y_bound - 1];
        end
        
        if ClearTrapInfo(i)
            cTimelapse.clearTrapInfo();
            % no longer necessary to clearOldTrapInfo
            cExperiment.clearOldTrapInfo(currentPos) = false;
            % position has no longer been segmented
            cExperiment.posSegmented(currentPos) = false;
        end
        
        % if there are no traps, continue to the next iteration of the for loop
        % having only clearedTrapInfo
        if ~cTimelapse.trapsPresent
            continue
        end
        
        % check whether image needs to be rescaled for traps.
        cTimelapse.determineImSize(cExperiment.cCellVision.pixelSize);
        
        previous_locations = cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations;
        
        cTSD = cTrapSelectDisplay(cTimelapse,cExperiment.cCellVision,cTimelapse.timepointsToProcess(1),[],ExclusionZone);
        uiwait(cTSD.figure);
        
        if i==1 && TrackFirstTimepoint
            
            
            cTimelapse.trackTrapsThroughTime(cExperiment.cCellVision,cTimelapse.timepointsToProcess);
            TotalXDrift = mode([cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(end)).trapLocations(:).xcenter] - ...
                [cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations(:).xcenter],2);
            TotalYDrift = mode([cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(end)).trapLocations(:).ycenter] - ...
                [cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations(:).ycenter],2);
            
            
            %add new exclusions zones based on drift.
            if TotalXDrift>0
                ExclusionZone = [ExclusionZone ;(cTimelapse.imSize(2) - (TotalXDrift + x_bound)), 1, ...
                    TotalXDrift + x_bound -1, cTimelapse.imSize(1)-1];
                
            else
                ExclusionZone = [ExclusionZone ;1, 1, ...
                    (abs(TotalXDrift) + x_bound -1), cTimelapse.imSize(1)-1];
                
            end
            
            if TotalYDrift>0
                ExclusionZone = [ExclusionZone ;...
                    [1, (cTimelapse.imSize(1) - (TotalYDrift + y_bound)) ...
                    cTimelapse.imSize(2)-1, (TotalYDrift + y_bound - 1)] ];
                
            else
                ExclusionZone = [ExclusionZone ;...
                    [1, 1, ...
                    cTimelapse.imSize(2) - 1, (abs(TotalYDrift) + y_bound)] ];
                
            end
            
            % for position 1, remove traps that are now identified as
            % falling outside the drift zone.
            cTD.ExclusionZones = ExclusionZone;
            trapsToRemove = cTD.identifyExcludedTraps(cTD.trapLocations,previous_locations);
            cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations(trapsToRemove) = [];
            
        end
        
        cExperiment.saveTimelapseExperiment;
    end
    
    % Finish logging protocol
    cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end
