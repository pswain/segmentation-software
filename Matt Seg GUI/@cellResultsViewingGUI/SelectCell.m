function SelectCell(CellResGUI)
% function SelectCell(CellResGUI,src,event) Callback for when the cell
% selection is changed in the cell selection list

cell_to_be_selected = CellResGUI.CellSelectListInterface.Value;


%check if position has changed and update if necessary
if CellResGUI.CellsForSelection(cell_to_be_selected,1) ~= CellResGUI.CellsForSelection(CellResGUI.CellSelected,1)
    CellResGUI.cExperiment.loadCurrentTimelapse(CellResGUI.CellsForSelection(cell_to_be_selected,1));
end
CellResGUI.CellSelected = cell_to_be_selected;
 
CellResGUI.CellRes_slider_cb;


end