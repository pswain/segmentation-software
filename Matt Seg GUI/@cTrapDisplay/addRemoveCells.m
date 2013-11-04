function addRemoveCells(cDisplay,subAx,trap)

cp=get(subAx,'CurrentPoint');

key=cDisplay.KeyPressed;
cDisplay.KeyPressed = [];
%reset the key value to [] because the key release function will not
%trigger when a new GUI is opened by the call back.


cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = floor(get(cDisplay.slider,'Value'));

if strcmp(key,cDisplay.CurateTracksKey)
    

    CellNumNearestCell = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);
    
    if ~isempty(CellNumNearestCell)
        
        TrackingCurator = curateCellTrackingGUI(cDisplay.cTimelapse,timepoint,trap);
        TrackingCurator.CellLabel = cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(CellNumNearestCell);
        
    end
    
    
    
else
    
    if strcmp(get(gcbf,'SelectionType'),'alt')
        disp(['remove circle at ', num2str([Cx,Cy])]);
        selection='remove';
    else
        disp(['add circle at ', num2str([Cx,Cy])]);
        selection='add';
    end
    method='hough';
    cDisplay.cTimelapse.addRemoveCells(cDisplay.cCellVision,timepoint,trap,selection,cellPt, method, cDisplay.channel)
    slider_cb(cDisplay);

end

end



