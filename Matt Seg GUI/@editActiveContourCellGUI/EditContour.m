function EditContour(CellACDisplay,SubAxes,SubAxesIndex)
%a function that should take the inputs above and change the contour of the
%cell defined by TrapNum,CellNum based on the point pt clicked by the user.

cp=get(SubAxes,'CurrentPoint');
%convert click coords to coords relative to the center
Cx=cp(1,1) - (size(CellACDisplay.CellOutlines,2)+1)/2;
Cy=cp(1,2) - (size(CellACDisplay.CellOutlines,1)+1)/2;
timepoint = CellACDisplay.subAxesTimepoints(SubAxesIndex);

if any([Cx Cy]~=0)
    if strcmp(get(gcbf,'SelectionType'),'alt')
        fprintf('no right click function at the moment. Do you have a suggestion?\n')
    else
        fprintf('modified cell %d in trap %d at timepoint %d',CellACDisplay.CellLabel,CellACDisplay.trapIndex,timepoint)
        CellACDisplay.ttacObject.AlterOutlineFromGivenPoint(timepoint,CellACDisplay.trapIndex,CellACDisplay.ttacObject.ReturnCellIndex(timepoint,CellACDisplay.trapIndex,CellACDisplay.CellLabel),[Cx Cy]);
        CellACDisplay.CellOutlines(:,:,timepoint) = CellACDisplay.getCellOutlines(timepoint,CellACDisplay.trapIndex,CellACDisplay.CellLabel);
        CellACDisplay.UpdateImages;
    end
end

end