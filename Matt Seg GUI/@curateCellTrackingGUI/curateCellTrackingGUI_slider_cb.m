function curateCellTrackingGUI_slider_cb(TrackingCurator)
%slider call back for editActiveContourCellGUI. Basically the function
%called everytime the slider of that GUI is moved.

Timepoint = get(TrackingCurator.slider,'Value');
Timepoint=floor(Timepoint);
TrackingCurator.UpdateTimepointsInStrip(Timepoint);
TrackingCurator.UpdateImages;

end

% title(cDisplay.subAxes(1),int2str(timepoint));
