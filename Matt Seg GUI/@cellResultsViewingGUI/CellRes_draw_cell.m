function CellRes_draw_cell( CellResGUI )
% CellRes_draw_cell( CellResGUI ) draws the cell image in the image box.


trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

cell_number = find(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number);

image_channel_number = CellResGUI.SelectImageChannelButton.Value;

cell_image = CellResGUI.cExperiment.cTimelapse.returnSingleTrapTimepoint(trap_number,timepoint,image_channel_number);

if ~isempty(cell_number) && CellResGUI.ShowcellOutline
    cell_outline = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cell(cell_number).segmented;
else
    cell_outline = false([CellResGUI.cExperiment.cTimelapse.cTrapSize.bb_width CellResGUI.cExperiment.cTimelapse.cTrapSize.bb_height]*2 + 1);
end

show_image = OverlapGreyRed(double(cell_image),cell_outline,[],[],true,true,CellResGUI.ImageRange);

imshow(show_image,'Parent',CellResGUI.CellImageHandle);

end

