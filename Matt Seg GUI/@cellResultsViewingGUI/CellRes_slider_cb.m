function CellRes_slider_cb( CellResGUI)
%CellRes_slider_cb( CellResGUI) slider call back, just updates plot and
%cell image when slider value changes.

CellResGUI.TimepointSelected = round(CellResGUI.slider.Value);

CellResGUI.CellRes_draw_cell;
CellResGUI.CellRes_plot;

end

