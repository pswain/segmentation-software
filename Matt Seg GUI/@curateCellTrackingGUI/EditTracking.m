function EditTracking(TrackingCurator,SubAxes,SubAxesIndex,src,event)
% EditTracking(TrackingCurator,SubAxes,SubAxesIndex)
%
% does various things based on the button being held down (which is stored
% in TrackingCurator.keyPressed
%
% no button                        :    edit tracking and select cell label
%                                       to store in CellLabel field
% TrackingCurator.outlineEditKey   :    change the active contour result
% TrackingCurator.addRemoveKey     :    add/remove cells making an active
%                                       contour outline.

cp=get(SubAxes,'CurrentPoint');
%convert click coords to coords relative to the center

Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = TrackingCurator.subAxesTimepoints(SubAxesIndex);

OutlinesToUpdate = [];
TrapInfoMissing = [];
    
if isempty(TrackingCurator.keyPressed)
    % change tracking
    CellNumNearestCell = TrackingCurator.cTimelapse.ReturnNearestCellCentre(timepoint,TrackingCurator.trapIndex,cellPt);
    
    if ~isempty(CellNumNearestCell)
        if strcmp(get(gcbf,'SelectionType'),'alt')
            TrackingCurator.CellLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
            fprintf('Cell label %d selected\n',TrackingCurator.CellLabel)
            TrackingCurator.UpdateImages;
            OutlinesToUpdate = [];
        else
            % Update the log
            logmsg(TrackingCurator.cTimelapse,'Modified cell with label %d in trap %d at timepoint %d to have label %d',...
                TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell),...
                TrackingCurator.trapIndex,timepoint,TrackingCurator.CellLabel);

            oldLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
            OutlinesToUpdate = [];
            TrapInfoMissing = [];
            % new highest label - if new cells need to be added.
            newCellLabel = TrackingCurator.cTimelapse.returnMaxCellLabel(TrackingCurator.trapIndex)+1;
            for TP = timepoint:max(TrackingCurator.cTimelapse.timepointsToProcess)
                if ~isempty(TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo)
                    UpdateOutline = false;
                    TPLabels = TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel;
                    
                    if any(TPLabels == oldLabel) && oldLabel ~= TrackingCurator.CellLabel
                        TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==oldLabel) = TrackingCurator.CellLabel;
                        UpdateOutline = true; %update list of TP at which to update the outline
                    end
                    
                    if any(TPLabels == TrackingCurator.CellLabel ) && oldLabel ~= TrackingCurator.CellLabel %the and in this statement is added in case people pick the cell that already has the label
                        TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==TrackingCurator.CellLabel) = newCellLabel;
                        UpdateOutline = true;
                    end
                    
                    if UpdateOutline
                        OutlinesToUpdate = [OutlinesToUpdate TP];
                    end

                    
                else
                    TrapInfoMissing = [TrapInfoMissing TP];
                    
                end
                
            end
            
            
            
        end
    end
elseif strcmp(TrackingCurator.keyPressed,TrackingCurator.separateTrackingKey)
    % break tracking from the new cell so that the cell is seaparted from
    % that tp forwards.
    CellNumNearestCell = TrackingCurator.cTimelapse.ReturnNearestCellCentre(timepoint,TrackingCurator.trapIndex,cellPt);
    if ~isempty(CellNumNearestCell)
        % Update the log
        logmsg(TrackingCurator.cTimelapse,'Modified cell with label %d in trap %d at timepoint %d to have label %d',...
            TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell),...
            TrackingCurator.trapIndex,timepoint,TrackingCurator.CellLabel);
        
        oldLabel = TrackingCurator.CellLabel;%TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
        OutlinesToUpdate = [];
        TrapInfoMissing = [];
        % new highest label - if new cells need to be added.
        newCellLabel = TrackingCurator.cTimelapse.returnMaxCellLabel(TrackingCurator.trapIndex)+1;
        for TP = timepoint:max(TrackingCurator.cTimelapse.timepointsToProcess)
            if ~isempty(TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo)
                UpdateOutline = false;
                TPLabels = TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel;
                
                if any(TPLabels == oldLabel) %&& oldLabel ~= TrackingCurator.CellLabel
                    TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==oldLabel) = newCellLabel;
                    UpdateOutline = true; %update list of TP at which to update the outline
                end
%                 if any(TPLabels == TrackingCurator.CellLabel ) && oldLabel ~= TrackingCurator.CellLabel %the and in this statement is added in case people pick the cell that already has the label
%                     TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==TrackingCurator.CellLabel) = newCellLabel;
%                     UpdateOutline = true;
%                 end
                if UpdateOutline
                    OutlinesToUpdate = [OutlinesToUpdate TP];
                end
            else
                TrapInfoMissing = [TrapInfoMissing TP];
            end
        end
    end
    
elseif strcmp(TrackingCurator.keyPressed,TrackingCurator.outlineEditKey)
    % change active contour result
    CellIndex = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel == TrackingCurator.CellLabel;
    
    if any(CellIndex)
        
        radii = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).cellRadii;
        % sometimes the centre gets saved as an integer for some reason
        centre = double(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).cellCenter);
        angles = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).cellAngle;
        
        radii =  ACBackGroundFunctions.edit_radii_from_point(cellPt,...
            centre,...
            radii',...
            angles');
        
        TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).cellRadii = radii;

        TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).segmented = ...
            sparse(ACBackGroundFunctions.get_outline_from_radii( radii',angles',centre,...
            size(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).segmented)));
        
        OutlinesToUpdate = timepoint;
    else
        OutlinesToUpdate=[];
    end
elseif strcmp(TrackingCurator.keyPressed,TrackingCurator.addRemoveKey)
    
    if strcmp(get(gcbf,'SelectionType'),'alt')
        logmsg(TrackingCurator.cTimelapse,'Remove cell at (%0.0f,%0.0f) in trap %d',Cx,Cy,TrackingCurator.trapIndex);
        selection='remove';
    else
        logmsg(TrackingCurator.cTimelapse,'Add new cell at (%0.0f,%0.0f) in trap %d',Cx,Cy,TrackingCurator.trapIndex);
        selection='add';
        TrackingCurator.PermuteVector(TrackingCurator.cTimelapse.returnMaxCellLabel(TrackingCurator.trapIndex) +1) =...
            TrackingCurator.cTimelapse.returnMaxCellLabel(TrackingCurator.trapIndex) +1;
    
    end
    
        TrackingCurator.cTimelapse.addRemoveCells(timepoint,TrackingCurator.trapIndex,selection,round(cellPt));
        
    OutlinesToUpdate = timepoint;
    
end

for TP = OutlinesToUpdate
    TrackingCurator.CellOutlines(:,:,TP) =TrackingCurator.getCellOutlines(TP);
end

if ~isempty(TrapInfoMissing)
    fprintf('\n \nWARNING!! Trap info missing for the following timepoints:')
    display(TrapInfoMissing)
    fprintf('\n \n')
end

TrackingCurator.UpdateImages();

end
