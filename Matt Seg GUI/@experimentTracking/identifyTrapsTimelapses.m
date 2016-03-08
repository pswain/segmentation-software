function identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify,TrackFirstTimepoint,ClearTrapInfo)
% identifyTrapsTimelapses(cExperiment,cCellVision,positionsToIdentify,TrackFirstTimepoint,ClearTrapInfo)
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
% ClearTrapInfo      :  boolean. if true clears all the previous trapInfo
%                       other than fielnames. Can be useful if changing
%                       cCellvision models for example.

if nargin<3 ||isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

if nargin<4 || isempty(TrackFirstTimepoint)



Message=(['Each position of the experiment will be displayed one by one. The program will guess where the traps are present at first, but you will need to add (left-click) or remove' ...
    ' (right-click) traps to make sure that the trap selection is properly performed. It is generally advisable to look at the timelapse for a single position to make sure the stage ' ...
    'didnt drift too much during the experiment. If it did drift you want to make sure not to select traps that will go out of the field of view during the experiment.']);
h = helpdlg(Message);
uiwait(h);
    
Positive ='track first timepoint' ;
Negative ='no thanks' ;
TrackFirstTimpointDlgOut = questdlg(...
    ['Would you like to track the first timepoint to find drift and use this to try and rule out'...
    ' traps that will be lost due to drift? This will delete any cell information in the first timepoint'...
    ' submitted.This is only useful if selecting traps in numerous positions and if the experiment has a'...
    ' reasonably large drift and if you only want analyse positions present for the whole duration.']...
    ,'track first timepoint to remove drift?',Positive,Negative,Negative);

TrackFirstTimepoint = strcmp(TrackFirstTimpointDlgOut,Positive);

end

if nargin<5 || isempty(ClearTrapInfo)
    ClearTrapInfo = false;
end

% Start logging protocol
cExperiment.logger.start_protocol('selecting traps',length(positionsToIdentify));
try

for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);

    cTimelapse=cExperiment.loadCurrentTimelapse(currentPos);
    if ClearTrapInfo
        cTimelapse.clearTrapInfo;
    end
    if TrackFirstTimepoint
        if i==1
            cTrapSelectDisplay(cTimelapse,cCellVision,cExperiment.timepointsToProcess(1));
            uiwait();
            cTimelapse.trackTrapsThroughTime(cCellVision,cTimelapse.timepointsToProcess);
            TotalXDrift = mode([cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(end)).trapLocations(:).xcenter] - ...
                [cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations(:).xcenter],2);
            TotalYDrift = mode([cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(end)).trapLocations(:).ycenter] - ...
                [cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapLocations(:).ycenter],2);
            
            %exclude traps more than on quarter out of image at the
            %beginning or end.
            y_bound = round(cTimelapse.cTrapSize.bb_height/2);
            x_bound = round(cTimelapse.cTrapSize.bb_width/2);
            ExclusionZone = [1 1 cTimelapse.imSize(2) y_bound;...
                                1 1  x_bound cTimelapse.imSize(1);...
                                (cTimelapse.imSize(2) - x_bound) 1 cTimelapse.imSize(2) cTimelapse.imSize(1);...
                                1 (cTimelapse.imSize(1) - y_bound) cTimelapse.imSize(2) cTimelapse.imSize(1)];
            if TotalXDrift>0
                ExclusionZone = [ExclusionZone ;(cTimelapse.imSize(2) - (TotalXDrift + ceil(x_bound))) 1 ...
                                    cTimelapse.imSize(2) cTimelapse.imSize(1)];
                
            else
                ExclusionZone = [ExclusionZone ;1 1 ...
                                    (abs(TotalXDrift) + ceil(x_bound)) cTimelapse.imSize(1)];
                
            end
            
             if TotalYDrift>0
                ExclusionZone = [ExclusionZone ;...
                                    [1 (cTimelapse.imSize(1) - (TotalYDrift + ceil(y_bound))) ...
                                    cTimelapse.imSize(2) cTimelapse.imSize(1)] ];
                
            else
                ExclusionZone = [ExclusionZone ;...
                                    [1 1 ...
                                    cTimelapse.imSize(2) (abs(TotalYDrift) + ceil(y_bound))] ];
                 
            end
            
        else
            
            cTrapSelectDisplay(cTimelapse,cCellVision,cExperiment.timepointsToProcess(1),[],ExclusionZone);
            uiwait();
            
        end
    else
        cTrapSelectDisplay(cTimelapse,cCellVision,cExperiment.timepointsToProcess(1));
        uiwait();
    end
    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end
