function ActiveContourButtonTimelapseTrapsGUI( cTrapsGUI )
%ActiveContourButtonTimelapseTrapsGUI( cTrapsGUI ) a button that either
%instantiaties or runs the active contour method depending on what has
%happened before.

if cTrapsGUI.ActiveContourButtonState == 1
    cTrapsGUI.cTimelapse.InstantiateActiveContourTimelapseTraps;
    cTrapsGUI.cTimelapse.ActiveContourObject.getTrapInfoFromCellVision(cTrapsGUI.cCellVision);
    cTrapsGUI.ActiveContourButtonState = 2;
elseif cTrapsGUI.ActiveContourButtonState == 2
    cTrapsGUI.cTimelapse.RunActiveContourTimelapseTraps;
end



end

