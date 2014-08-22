function selectCell( hObject, cData )
%selectCell Track a chosen cell
%   Add a cell to be tracked by clicking on the image
%   Select the cell closest to point clicked and add it to the tracking
pos=get(hObject,'currentpoint');
h=get(hObject,'parent');
select=get(h,'selectiontype');
pos=pos(1,1:2);%Returns two sets of identical co-ordinate. Presumably one is for image, and one for axes
sliderVal=floor(get(cData.timepointSlider,'value'));
%disp(pos)
%=====================
%Check if it lies within a trap& get appropriate trap
%Check if this works, or if you need to have the position *in* the trap
%=====================

trapNum=getNearestTrapNumber(cData,sliderVal,pos);
nearestCell=cData.cTimelapse.ReturnNearestCellCentre(sliderVal,trapNum,pos);
nearestCell=cData.cTimelapse.cTimepoint(sliderVal).trapInfo(trapNum).cellLabel(nearestCell);
%disp(nearestCell)
%make sure the cell selected has data

%Check if it lies within a trap& get appropriate trap
if find(cData.cellsWithData==nearestCell)
    if strcmpi(select,'normal')
        cData.cellsToPlot(1,nearestCell)=1;
    elseif strcmpi(select,'alt')
        cData.cellsToPlot(1,nearestCell)=0;
        cData.trackingColors(nearestCell,1:3)=0;
    end
else
    disp('No data for cell');
end

end

