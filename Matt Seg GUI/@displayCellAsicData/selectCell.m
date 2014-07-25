function selectCell( hObject, cData )
%UNTITLED Track a chosen cell
%   Add a cell to be tracked by clicking on the image
%   Select the cell closest to point clicked and add it to the tracking
pos=get(hObject,'currentpoint');
h=get(hObject,'parent');
select=get(h,'selectiontype');
pos=pos(1,1:2);%Returns two sets of identical co-ordinate. Presumably one is for image, and one for axes
sliderVal=floor(get(cData.timepointSlider,'value'));
%disp(pos)
nearestCell=cData.cTimelapse.ReturnNearestCellCentre(sliderVal,1,pos);
nearestCell=cData.cTimelapse.cTimepoint(sliderVal).trapInfo.cellLabel(nearestCell);
%disp(nearestCell)
%make sure the cell selected has data
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

