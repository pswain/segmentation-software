function editActiveContourCell_slider_cb(CellACDisplay)
%slider call back for editActiveContourCellGUI. Basically the function
%called everytime the slider of that GUI is moved.

Timepoint = get(CellACDisplay.slider,'Value');
Timepoint=floor(Timepoint);
CellACDisplay.UpdateTimepointsInStrip(Timepoint);
CellACDisplay.UpdateImages;

end

