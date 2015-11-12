function ResetImageScale( CellResGUI )
%ResetImageScale( CellResGUI ) a simple function to reset the image scale
%so that the image scale max is the max of the the image currently
%displayed.

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

cell_number = find(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number);

image_channel_number = get(CellResGUI.SelectImageChannelButton,'Value');

cell_image = CellResGUI.cExperiment.cTimelapse.returnSingleTrapTimepoint(trap_number,timepoint,image_channel_number);

CellResGUI.ImageRange(2) = max(cell_image(:));

CellResGUI.CellRes_draw_cell;

end

