function CellRes_slider_cb( CellResGUI)
%CellRes_slider_cb( CellResGUI) slider call back.

CellResGUI.TimepointSelected = round(CellResGUI.slider.Value);

CellResGUI.CellRes_draw_cell;
CellResGUI.CellRes_plot;

end

