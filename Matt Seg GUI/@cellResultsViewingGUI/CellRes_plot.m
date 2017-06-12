function CellRes_plot(CellResGUI )
% CellRes_plot( CellResGUI ) plots the graph at the bottom. MIght be good
% to at some point allow custom plots.

cell_position = CellResGUI.CellsForSelection(CellResGUI.CellSelected,1);

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

button_fields = get(CellResGUI.SelectPlotFieldButton,'String');

plot_field = button_fields{get(CellResGUI.SelectPlotFieldButton,'Value')};

plot_channel = get(CellResGUI.SelectPlotChannelButton,'Value');

cell_data_index = (CellResGUI.cExperiment.cellInf(1).posNum == cell_position) &...
                  (CellResGUI.cExperiment.cellInf(1).trapNum == trap_number) & ...
                  (CellResGUI.cExperiment.cellInf(1).cellNum == cell_tracking_number);
if sum(cell_data_index == 1)
    %Hack to allow plotting of pH - based on a single standard curve so
    %will not be correct for all experiments
    if strcmp(plot_field,'pH')
        ratio=full(CellResGUI.cExperiment.cellInf(2).median(cell_data_index,:)./CellResGUI.cExperiment.cellInf(1).median(cell_data_index,:));
        cell_data=ratio*3.1+4.75;
    else
        cell_data = full(CellResGUI.cExperiment.cellInf(plot_channel).(plot_field)(cell_data_index,:));
    end
    axes(CellResGUI.PlotHandle);
    xInc=((1:size(cell_data,2)))*CellResGUI.TimepointSpacing;
    plot(xInc,cell_data,'-r');
    tData=cell_data;
    tData(tData==0)=[];
    yMin=min(tData);yMax=max(tData);
    try
        ylim([yMin yMax]);
        xlim([1 max(xInc(:))]);
    end
    hold on
    
    timepoint_index = CellResGUI.cExperiment.timepointsToProcess == timepoint;
    
    p = plot(timepoint*CellResGUI.TimepointSpacing,cell_data(timepoint_index),'ob');
    set(p,'MarkerFaceColor',get(p,'Color'));
    
    % mother plotting stuff
    if ~isempty(CellResGUI.cExperiment.lineageInfo)
    cell_mother_index = (CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum == cell_position) &...
                  (CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap == trap_number) & ...
                  (CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel == cell_tracking_number);

              if any(cell_mother_index)
                  
                  switch CellResGUI.birthTypeUse
                      case 'HMM'
                          birth_times = CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeHMM(cell_mother_index,:);
                      case 'Manual'
                          if ~isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'birthTimeManual')
                              CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual= ...
                                  CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeHMM;
                          end
                          birth_times = CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:);
                  end

                  birth_times(birth_times==0) = [];
                  
                  %weird quirk where birth times seems to be [1 0 0 0 ...]
                  %by default.
%                   if birth_times==1
%                       birth_times = [];
%                   end
                  ylim_plot = get(CellResGUI.PlotHandle,'Ylim');
                  for bi = 1:length(birth_times)
                      bt = birth_times(bi);
                      plot(CellResGUI.TimepointSpacing*(bt)*[1 1],ylim_plot,'-g')
                  end
                  if isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'deathTimeManual')
                      deathTime=CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual(cell_mother_index);
                      if deathTime>0
                          plot(CellResGUI.TimepointSpacing*(deathTime)*[1 1],ylim_plot,'-b')
                      end
                  end
                  
              end
    end
    
    
    hold off
    
else
    
    axes(CellResGUI.PlotHandle);
    
    plot(0,0,'o')
    
end

end

