function EditTracking(TrackingCurator,SubAxes,SubAxesIndex)
%a function that should take the inputs above and change the contour of the
%cell defined by TrapNum,CellNum based on the point pt clicked by the user.

cp=get(SubAxes,'CurrentPoint');
%convert click coords to coords relative to the center
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = TrackingCurator.subAxesTimepoints(SubAxesIndex);

CellNumNearestCell = TrackingCurator.cTimelapse.ReturnNearestCellCentre(timepoint,TrackingCurator.trapIndex,cellPt);

if ~isempty(CellNumNearestCell)
if strcmp(get(gcbf,'SelectionType'),'alt')
    TrackingCurator.CellLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
    fprintf('Cell label %d selected\n',TrackingCurator.CellLabel)
    TrackingCurator.UpdateImages;
else
    UpdateMaxCell = false;
    fprintf('modified cell with label %d in trap %d at timepoint %d to have label %d \n',TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell),TrackingCurator.trapIndex,timepoint,TrackingCurator.CellLabel)
    oldLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
    OutlinesToUpdate = [];
    for TP = timepoint:length(TrackingCurator.cTimelapse.cTimepoint)
        UpdateOutline = false;
        TPLabels = TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel;
        
        if any(TPLabels == oldLabel) && oldLabel ~= TrackingCurator.CellLabel
            TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==oldLabel) = TrackingCurator.CellLabel;
            UpdateOutline = true; %update list of TP at which to update the outline
        end
        
        if any(TPLabels == TrackingCurator.CellLabel ) && oldLabel ~= TrackingCurator.CellLabel %the and in this statement is added in case people pick the cell that already has the label
            TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==TrackingCurator.CellLabel) = TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex)+1; 
            UpdateMaxCell = true;
            UpdateOutline = true;
        end 
        
        if UpdateOutline
            OutlinesToUpdate = [OutlinesToUpdate TP];
        end
        
        
    end
    
    
    if UpdateMaxCell
        TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex) =TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex) +1;
        TrackingCurator.PermuteVector = [TrackingCurator.PermuteVector TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex)];
    end
    
    for TP = OutlinesToUpdate
        TrackingCurator.CellOutlines(:,:,TP) =TrackingCurator.getCellOutlines(TP,TrackingCurator.trapIndex);
    end
    
   
    TrackingCurator.UpdateImages;
end
end

end