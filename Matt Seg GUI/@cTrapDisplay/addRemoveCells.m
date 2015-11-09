function addRemoveCells(cDisplay,subAx,trap)
% addRemoveCells(cDisplay,subAx,trap)
%
% cDisplay  :   object of the cTrapDisplay class
% subAx     :   the axis which has been clicked
% trap      :   the index of the trap which displayed in the given sub
%               image indicated by subAx
%
% the function used for the mouse click call back. If the key held down on
% the keyboard matches the cDisplay.CurateTracksKey it opens the
% curateCellTrackingGUI for the nearest cell to the click. If no key is
% held down it either adds or removes a cell for left and right click
% respectively. This is done using the addRemoveCells method of cTimelapse.
% This ony happens if cTrapDisplay.trackOverlay is false (i.e. if the cells
% are not coloured by their label)

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
        TrackingCurator.UpdateImages;
        
    end
    
    
    
elseif ~cDisplay.trackOverlay
    
    if strcmp(get(gcbf,'SelectionType'),'alt')
        disp(sprintf('remove circle at (%0.0f,%0.0f) in trap %d ', Cx,Cy,trap));
        selection='remove';
    else
        disp(sprintf('add circle at (%0.0f,%0.0f) in trap %d ', Cx,Cy,trap));
        selection='add';
    end
    method='hough';
    cDisplay.cTimelapse.addRemoveCells(cDisplay.cCellVision,timepoint,trap,selection,cellPt, method, cDisplay.channel)
    slider_cb(cDisplay);

end

end



