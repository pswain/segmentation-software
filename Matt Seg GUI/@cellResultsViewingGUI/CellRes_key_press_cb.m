function CellRes_key_press_cb(CellResGUI,src,event)
%CellRes_key_press_cb(GUI,property,src,event)
%   Call back for the key press function for the CellResGUI shifts the
%   slider value on left right presses and the CellSelectd value on up/down
%   presses


cell_position = CellResGUI.CellsForSelection(CellResGUI.CellSelected,1);
trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);
cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);
if isfield(CellResGUI.cExperiment.lineageInfo,'motherInfo')
    cell_mother_index = (CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum == cell_position) &...
        (CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap == trap_number) & ...
        (CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel == cell_tracking_number);
end

% CellResGUI.slider.Enable='off';
switch event.Key
    case 'downarrow' 
        cell_value = get(CellResGUI.CellSelectListInterface,'Value')+1;
        if cell_value>length(get(CellResGUI.CellSelectListInterface,'String'))
            cell_value = length(get(CellResGUI.CellSelectListInterface,'String'));
        end
        set(CellResGUI.CellSelectListInterface,'Value',cell_value);
    case 'space' %so that space moves down one so you don't have to move your hands
        cell_value = get(CellResGUI.CellSelectListInterface,'Value')+1;
        if cell_value>length(get(CellResGUI.CellSelectListInterface,'String'))
            cell_value = length(get(CellResGUI.CellSelectListInterface,'String'));
        end
        set(CellResGUI.CellSelectListInterface,'Value',cell_value);
    case 'uparrow'
        cell_value = get(CellResGUI.CellSelectListInterface,'Value')-1;
        if cell_value<get(CellResGUI.CellSelectListInterface,'Min')
            cell_value = get(CellResGUI.CellSelectListInterface,'Min');
        end
        set(CellResGUI.CellSelectListInterface,'Value',cell_value);
    case 'leftarrow'
%         slider_value =  get(CellResGUI.slider,'Value') - 1;
        slider_value =  CellResGUI.slider.Value - 1;
        sMin=CellResGUI.slider.Min;
        if slider_value<sMin%get(CellResGUI.slider,'Min')
            slider_value = sMin;%get(CellResGUI.slider,'Min');
        end
        %         set(CellResGUI.slider,'Value',slider_value);
        CellResGUI.slider.Value=slider_value;
    case 'rightarrow'
        %         slider_value =  get(CellResGUI.slider,'Value') + 1;
        slider_value =  CellResGUI.slider.Value + 1;
        sMax=CellResGUI.slider.Max;
        if slider_value>sMax%get(CellResGUI.slider,'Max')
            slider_value = sMax;%get(CellResGUI.slider,'Max');
        end
        %         set(CellResGUI.slider,'Value',slider_value);
        CellResGUI.slider.Value=slider_value;
    case 'b'
        currTP =  get(CellResGUI.slider,'Value');
        fprintf(['\nAdded a new birth at ' num2str(currTP)]);
        
        CellResGUI.needToSave = ...
            editBirthManual( CellResGUI.cExperiment,'+', currTP,cell_position,trap_number,cell_tracking_number,NaN ) || ...
            CellResGUI.needToSave;
        CellResGUI.CellRes_plot;
        CellResGUI.CellRes_draw_cell;
        
    case 'x'
        currTP =  get(CellResGUI.slider,'Value');
        fprintf(['\nRemove birth closest to TP ' num2str(currTP)]);
        % didn't understand all that stuff to do with death. seemed janky,
        % so I deleted it.
        CellResGUI.needToSave = ...
            editBirthManual( CellResGUI.cExperiment,'-', currTP,cell_position,trap_number,cell_tracking_number,NaN ) || ...
            CellResGUI.needToSave ;
        CellResGUI.CellRes_plot;
        CellResGUI.CellRes_draw_cell;
        
    case 't'
        trap=trap_number;
        CellNumNearestCell=cell_tracking_number;
        currTP =  floor(get(CellResGUI.slider,'Value'));
        TrackingCurator = curateCellTrackingGUI(CellResGUI.cExperiment.cTimelapse,currTP,trap);
        TrackingCurator.CellLabel = CellNumNearestCell;
        TrackingCurator.UpdateImages;
        CellResGUI.needToSave=true;
    case 'd' %death
        currTP =  get(CellResGUI.slider,'Value');
        fprintf(['\nAdded death at ' num2str(currTP)]);
        CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual(cell_mother_index)=currTP;
        CellResGUI.birthTypeUse='Manual';CellResGUI.CellRes_plot;
        CellResGUI.needToSave=true;
        CellResGUI.CellRes_plot;
        CellResGUI.CellRes_draw_cell;

end


end
