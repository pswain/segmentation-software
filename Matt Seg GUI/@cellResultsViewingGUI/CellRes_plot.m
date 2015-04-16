function CellRes_plot(CellResGUI )
% CellRes_plot( CellResGUI ) plots the graph at the bottom. MIght be good
% to at some point allow custom plots.

cell_position = CellResGUI.CellsForSelection(CellResGUI.CellSelected,1);

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

plot_field = CellResGUI.SelectPlotFieldButton.String{CellResGUI.SelectPlotFieldButton.Value};

plot_channel = CellResGUI.SelectPlotChannelButton.Value;

cell_data_index = (CellResGUI.cExperiment.cellInf(1).posNum == cell_position) &...
                  (CellResGUI.cExperiment.cellInf(1).trapNum == trap_number) & ...
                  (CellResGUI.cExperiment.cellInf(1).cellNum == cell_tracking_number);
if sum(cell_data_index == 1)
    
    cell_data = full(CellResGUI.cExperiment.cellInf(plot_channel).(plot_field)(cell_data_index,:));
    
    axes(CellResGUI.PlotHandle);
    
    plot(CellResGUI.cExperiment.timepointsToProcess*CellResGUI.TimepointSpacing,cell_data,'-r');
    
    hold on
    
    timepoint_index = CellResGUI.cExperiment.timepointsToProcess == timepoint;
    
    p = plot(timepoint*CellResGUI.TimepointSpacing,cell_data(timepoint_index),'ob');
    p.MarkerFaceColor = p.Color;
    
    hold off
    
else
    
    axes(CellResGUI.PlotHandle);
    
    plot(0,0,'o')
    
end

end

