function SelectCell(CellResGUI,src,event)
% function SelectCell(CellResGUI,src,event) Callback for when the cell
% selection is changed in the cell selection list

cell_to_be_selected = get(CellResGUI.CellSelectListInterface,'Value');


%check if position has changed and update if necessary
% if zero is just for first selection - crude I know
if CellResGUI.CellSelected == 0 || CellResGUI.CellsForSelection(cell_to_be_selected,1) ~= CellResGUI.CellsForSelection(CellResGUI.CellSelected,1)
    if CellResGUI.needToSave
        h = warndlg('Going to save data ... may take a minute');  
        CellResGUI.cExperiment.saveTimelapseExperiment;
    end
    CellResGUI.needToSave=false;
    CellResGUI.cExperiment.loadCurrentTimelapse(CellResGUI.CellsForSelection(cell_to_be_selected,1));
end
CellResGUI.CellSelected = cell_to_be_selected;
 
CellResGUI.CellRes_slider_cb;


end