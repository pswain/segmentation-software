function CellRes_key_press_cb(CellResGUI,src,event)
%CellRes_key_press_cb(GUI,property,src,event)
%   Call back for the key press function for the CellResGUI


switch event.Key
    case 'downarrow'
        cell_value = CellResGUI.CellSelectListInterface.Value+1;
        if cell_value>length(CellResGUI.CellSelectListInterface.String)
            cell_value = length(CellResGUI.CellSelectListInterface.String);
        end
        CellResGUI.CellSelectListInterface.Value = cell_value;
    case 'uparrow'
        cell_value = CellResGUI.CellSelectListInterface.Value-1;
        if cell_value<CellResGUI.CellSelectListInterface.Min
            cell_value = CellResGUI.CellSelectListInterface.Min;
        end
        CellResGUI.CellSelectListInterface.Value = cell_value;
    case 'leftarrow'
        slider_value =  CellResGUI.slider.Value - 1;
        if slider_value<CellResGUI.slider.Min
            slider_value = CellResGUI.CellSelectListInterface.Min;
        end
        CellResGUI.slider.Value = slider_value;
    case 'rightarrow'
        slider_value =  CellResGUI.slider.Value + 1;
        if slider_value>CellResGUI.slider.Max
            slider_value = CellResGUI.CellSelectListInterface.Max;
        end
        CellResGUI.slider.Value = slider_value;
end


end
