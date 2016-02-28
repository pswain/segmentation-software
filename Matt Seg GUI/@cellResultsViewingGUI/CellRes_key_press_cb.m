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
        if ~isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'birthTimeManual') ...
                | isempty(CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual)
            CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual= ...
                CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeHMM;
            %in case the cell numbers are editted in the future, want to
            %record the current list of mother trap/pos numbers
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.trapNum=CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap;
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.posNum=CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum;
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.motherLabel=CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel;
        end
        birth_times = CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:);
        birth_times=birth_times(birth_times>0);
        birth_times(end+1)=currTP;birth_times=sort(birth_times,'ascend');
        CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,1:length(birth_times))= ...
            birth_times;
        CellResGUI.birthTypeUse='Manual';CellResGUI.CellRes_plot;
        CellResGUI.needToSave=true;
    case 'x'
        currTP =  get(CellResGUI.slider,'Value');
        fprintf(['\nRemove birth closest to TP ' num2str(currTP)]);
        if ~isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'birthTimeManual') ...
                | isempty(CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual)
            CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual= ...
                CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeHMM;
                 %in case the cell numbers are editted in the future, want to
            %record the current list of mother trap/pos numbers
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.trapNum=CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap;
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.posNum=CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum;
            CellResGUI.cExperiment.lineageInfo.motherInfo.manualInfo.motherLabel=CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel;
        end
        birth_times = CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:);
        birth_times=birth_times(birth_times>0);
        dist_births=pdist2(birth_times',currTP);
        [v ind]=min(dist_births);
        isdeath=false;
        if isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'deathTimeManual')
            deathTime=CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual(cell_mother_index);
            dist_death=pdist2(deathTime,currTP);
            if dist_death<v
                isdeath=true;
                CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index)=0;
            end
        end
        if ~isdeath
            birth_times(ind)=[];birth_times=sort(birth_times,'ascend');
            birth_times(end+1)=0;
            CellResGUI.cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,1:length(birth_times))= ...
                birth_times;
        end
        CellResGUI.birthTypeUse='Manual';CellResGUI.CellRes_plot;
        CellResGUI.needToSave=true;
    case 't'
        %         CellNumNearestCell = cDisplay.cTimelapse.ReturnNearestCellCentre(timepoint,trap,cellPt);
        trap=trap_number;
        CellNumNearestCell=cell_tracking_number;
        currTP =  floor(get(CellResGUI.slider,'Value'));
        TrackingCurator = curateCellTrackingGUI(CellResGUI.cExperiment.cTimelapse,currTP,trap);
        TrackingCurator.CellLabel = CellNumNearestCell;
        TrackingCurator.UpdateImages;
        CellResGUI.needToSave=true;
    case 'd'
        currTP =  get(CellResGUI.slider,'Value');
        fprintf(['\nAdded death at ' num2str(currTP)]);
        if ~isfield(CellResGUI.cExperiment.lineageInfo.motherInfo,'deathTimeManual') ...
                || isempty(CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual)
            CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual=...
                zeros([length(CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum) 1]);
        end
        CellResGUI.cExperiment.lineageInfo.motherInfo.deathTimeManual(cell_mother_index)=currTP;
        CellResGUI.birthTypeUse='Manual';CellResGUI.CellRes_plot;
        CellResGUI.needToSave=true;


end
% CellResGUI.slider.Enable='on';


end
