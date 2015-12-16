function addRemoveCells(cDisplay,subAx,trap)

key=cDisplay.KeyPressed;
cDisplay.KeyPressed = [];
%reset the key value to [] because the key release function will not
%trigger when a new GUI is opened by the call back.

cp=get(subAx,'CurrentPoint');
cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = floor(get(cDisplay.slider,'Value'));

if strcmp(key,cDisplay.CurateTracksKey)
    
    
    CellNumNearestCell = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);
    
    if ~isempty(CellNumNearestCell)
        
        TrackingCurator = curateCellTrackingGUI(cDisplay.cTimelapse,cDisplay.cCellVision,timepoint,trap);
        TrackingCurator.CellLabel = cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(CellNumNearestCell);
        TrackingCurator.UpdateImages;
    end
    
    
    
else

if strcmp(get(gcbf,'SelectionType'),'alt')
    disp(['remove circle at ', num2str([Cx,Cy])]);
    selection=0;
else
    disp(['add circle at ', num2str([Cx,Cy])]);
    selection=1;
end


loc = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);
cDisplay.cTimelapse.cellsToPlot(trap,cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(loc))=selection;



end
%
slider_cb(cDisplay);

