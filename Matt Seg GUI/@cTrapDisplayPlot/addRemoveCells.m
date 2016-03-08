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
    % Update the log
    logmsg(cDisplay.cTimelapse,'Unselecting cell at (%0.0f,%0.0f) in trap %d',Cx,Cy,trap);
    selection=0;
else
    % Update the log
    logmsg(cDisplay.cTimelapse,'Selecting cell at (%0.0f,%0.0f) in trap %d',Cx,Cy,trap);
    selection=1;
end


loc = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);
cDisplay.cTimelapse.cellsToPlot(trap,cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(loc))=selection;



end
%
slider_cb(cDisplay);

