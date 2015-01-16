function CellRes_plot(CellResGUI )
% CellRes_plot( CellResGUI ) plots the graph at the bottom.

cell_position = CellResGUI.CellsForSelection(CellResGUI.CellSelected,1);

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

cell_number = find(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number);

plot_field = CellResGUI.SelectPlotFieldButton.String{CellResGUI.SelectPlotFieldButton.Value};

plot_channel = CellResGUI.SelectPlotChannelButton.Value;

cell_data_index = (CellResGUI.cExperiment.cellInf.posNum == cell_position) &...
                  (CellResGUI.cExperiment.cellInf.trapNum == trap_number) & ...
                  (CellResGUI.cExperiment.cellInf.cellNum == cell_tracking_number);
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

