function chooseCellToEdit(cDisplay,subAx,trap)

cp=get(subAx,'CurrentPoint');
cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = floor(get(cDisplay.slider,'Value'));


CellNumNearestCell = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);

if ~isempty(CellNumNearestCell)
    
    editActiveContourCellGUI(cDisplay.ttacObject,trap,CellNumNearestCell,timepoint);
    
end
end