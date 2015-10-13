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
    
    plot(((1:size(cell_data,2)))*CellResGUI.TimepointSpacing,cell_data,'-r');
    
    hold on
    
    timepoint_index = CellResGUI.cExperiment.timepointsToProcess == timepoint;
    
    p = plot(timepoint*CellResGUI.TimepointSpacing,cell_data(timepoint_index),'ob');
    p.MarkerFaceColor = p.Color;
    
    % mother plotting stuff
    
    cell_mother_index = (CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum == cell_position) &...
                  (CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap == trap_number) & ...
                  (CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel == cell_tracking_number);
              if any(cell_mother_index)
                  
                  birth_times = CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeHMM(cell_mother_index,:);
                  birth_times(birth_times==0) = [];
                  
                  %weird quirk where birth times seems to be [1 0 0 0 ...]
                  %by default.
                  if birth_times==1
                      birth_times = [];
                  end
                  ylim_plot = get(CellResGUI.PlotHandle,'Ylim');
                  for bi = 1:length(birth_times)
                      bt = birth_times(bi);
                      
                      plot(CellResGUI.TimepointSpacing*(bt)*[1 1],ylim_plot,'-g')
                      
                  end
                  
              end
    
    
    hold off
    
else
    
    axes(CellResGUI.PlotHandle);
    
    plot(0,0,'o')
    
end

end

