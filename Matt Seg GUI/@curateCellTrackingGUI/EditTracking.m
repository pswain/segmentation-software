function EditTracking(TrackingCurator,SubAxes,SubAxesIndex)
%a function that should take the inputs above and change the contour of the
%cell defined by TrapNum,CellNum based on the point pt clicked by the user.

first_timepoint = TrackingCurator.cTimelapse.timepointsToProcess(1);

cp=get(SubAxes,'CurrentPoint');
%convert click coords to coords relative to the center
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = TrackingCurator.subAxesTimepoints(SubAxesIndex);

OutlinesToUpdate = [];
TrapInfoMissing = [];

if isempty(TrackingCurator.keyPressed)

CellNumNearestCell = TrackingCurator.cTimelapse.ReturnNearestCellCentre(timepoint,TrackingCurator.trapIndex,cellPt);

if ~isempty(CellNumNearestCell)
if strcmp(get(gcbf,'SelectionType'),'alt')
    TrackingCurator.CellLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
    fprintf('Cell label %d selected\n',TrackingCurator.CellLabel)
    TrackingCurator.UpdateImages;
    UpdateMaxCell = false;
    OutlinesToUpdate = [];
else
    UpdateMaxCell = false;
    fprintf('modified cell with label %d in trap %d at timepoint %d to have label %d \n',TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell),TrackingCurator.trapIndex,timepoint,TrackingCurator.CellLabel)
    oldLabel = TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel(CellNumNearestCell);
    OutlinesToUpdate = [];
    TPsToUpdateMax = [];
    TrapInfoMissing = [];
    for TP = timepoint:length(TrackingCurator.cTimelapse.cTimepoint)
        if ~isempty(TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo)
            UpdateOutline = false;
            TPLabels = TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel;
            
            if any(TPLabels == oldLabel) && oldLabel ~= TrackingCurator.CellLabel
                TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==oldLabel) = TrackingCurator.CellLabel;
                UpdateOutline = true; %update list of TP at which to update the outline
            end
            
            if any(TPLabels == TrackingCurator.CellLabel ) && oldLabel ~= TrackingCurator.CellLabel %the and in this statement is added in case people pick the cell that already has the label
                TrackingCurator.cTimelapse.cTimepoint(TP).trapInfo(TrackingCurator.trapIndex).cellLabel(TPLabels==TrackingCurator.CellLabel) = TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex)+1;
                UpdateMaxCell = true;
                UpdateOutline = true;
            end
            
            if UpdateOutline
                OutlinesToUpdate = [OutlinesToUpdate TP];
            end
            if UpdateMaxCell
                TPsToUpdateMax = [TPsToUpdateMax TP];
            end
            
        else
            TrapInfoMissing = [TrapInfoMissing TP];
            
        end
    
    end
    
    

end
end

elseif strcmp(TrackingCurator.keyPressed,TrackingCurator.outlineEditKey)
    
    
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
    
    [px,py] = ACBackGroundFunctions.get_full_points_from_radii(radii',angles',centre,...
        size(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).segmented));
    
    TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(CellIndex).segmented = ...
        sparse(ACBackGroundFunctions.px_py_to_logical( px,py,size(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cell(1).segmented) ));
    
    OutlinesToUpdate = timepoint;
    else
        OutlinesToUpdate=[];
    end
    
    UpdateMaxCell = false;
    

elseif strcmp(TrackingCurator.keyPressed,TrackingCurator.addRemoveKey)

    if strcmp(get(gcbf,'SelectionType'),'alt')
       fprintf('remove circle at (%0.0f,%0.0f) in trap %d \n', Cx,Cy,TrackingCurator.trapIndex);
        selection='remove';
    else
        fprintf('add circle at (%0.0f,%0.0f) in trap %d \n', Cx,Cy,TrackingCurator.trapIndex);
        selection='add';
        TrackingCurator.PermuteVector(TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex) +1) =...
        TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex) +1;
    end
    method='elcoAC';
    TrackingCurator.cTimelapse.addRemoveCells([],timepoint,TrackingCurator.trapIndex,selection,round(cellPt), method, 1);
    OutlinesToUpdate = timepoint;
    UpdateMaxCell = false;

end

for TP = OutlinesToUpdate
    TrackingCurator.CellOutlines(:,:,TP) =TrackingCurator.getCellOutlines(TP,TrackingCurator.trapIndex);
end

if UpdateMaxCell
    NewCellLabel = TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex) +1;
    TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex) = NewCellLabel;
    TrackingCurator.PermuteVector(NewCellLabel) =  NewCellLabel;
    for TP = TPsToUpdateMax
    TrackingCurator.cTimelapse.cTimepoint(TP).trapMaxCellUTP(TrackingCurator.trapIndex) = NewCellLabel;
    end
end

if ~isempty(TrapInfoMissing)
    fprintf('\n \nWARNING!! Trap info missing for the following timepoints:')
    display(TrapInfoMissing)
    fprintf('\n \n')
end

if any(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel > TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex)) || ...
        any(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel > length(TrackingCurator.PermuteVector) )||...
            length(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel)> length(unique(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex).cellLabel))

fprintf('\n\n you got a problem at TP = %d,TI = %d, TrapMaxcell %d \n\n',timepoint,TrackingCurator.trapIndex,TrackingCurator.cTimelapse.cTimepoint(first_timepoint).trapMaxCell(TrackingCurator.trapIndex))
        
        disp(TrackingCurator.cTimelapse.cTimepoint(timepoint).trapInfo(TrackingCurator.trapIndex))
        disp(TrackingCurator.PermuteVector)
        
end

TrackingCurator.UpdateImages;


end