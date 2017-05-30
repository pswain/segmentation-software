classdef cellResultsViewingGUI<handle
            % CellResGUI=cellResultsViewingGUI(cExperiment) a GUI for
            % viewing the data extracted for single cells along with the
            % images of those cells at particular timepoints. Intended to
            % be used for checking data for obvious tracking errors and
            % such.
            % can also modify lineage info by clicking on image (left to
            % add, right to remove).
    properties
        figure = []; %output of the figure to which GUI is assigned
        cExperiment; % cExperiment object of the object
        PlotPanel; % Panel in which data is plotted
        TopPanel; % panel in which Settings are selected, cell is selected and cell image displayed
        SettingsPanel; % subpanel of top panel where settings are selected
        ChannelDataCode; % cell array indicating which data field correspond to which images 
        ShowcellOutline = true; % whether to show the outline of the cell in the image
        CellSelectListInterface; % GUI list of cells available for selection. Automatically populated when CellsForSelection is changed.
        CellsForSelection; % array used for populating cell select list
        CellsforSelectionDiplayString; %String cell constructed form the structure to make the cellSelectionInterface
        SelectImageChannelButton; %handle for image channel selection button
        SelectPlotChannelButton; %handle for plot channel selection button
        SelectPlotFieldButton; %handle for plot field selection button
        ResetImageScaleButton; %handle for image channel selection button
        CellSelected = 0; %a field to hold the index of the cell selected for plotting and imaging - updated by the cell selection call back
        TimepointSelected; %a field to hold the index of the timepoint selected for plotting and imaging - updated by the slider call back
        CellImageHandle; % handle for the axis on which the cell is drawn
        PlotHandle; % handle for the axes on which the data is plotted
        slider; %slider object
        TimepointSpacing = 5; % time between consecutive timepoints. Used in plotting to make a proper x axis
        ImageRange = [0 65536]; % range of pixel values that form the min and max of the image. Updated when the 'Reset Image Scale' button is pressed
        cellImageSize = []; % can set to be the size of the cell image to show. Useful if there are not traps and it will show a smaller area
        
        needToSave; %does the experiment need to be saved before continuing along - only if any edits have been made.
        birthTypeUse='HMM'; %which birthtime dataset should be shown. Can be 'HMM' or 'Manual';
    end % properties

    methods
        function CellResGUI=cellResultsViewingGUI(cExperiment)
            % CellResGUI=cellResultsViewingGUI(cExperiment) a GUI for
            % viewing the data extracted for single cells along with the
            % images of those cells at particular timepoints. Intended to
            % be used for checking data for obvious tracking errors and
            % such.
            % can also modify lineage info by clicking on image.
            
            if nargin<1 ||isempty(cExperiment)
                [filename, pathname] = uigetfile('*.mat', 'Pick a cExperiment File');
                if isequal(filename,0) || isequal(pathname,0)
                    disp('GUI construction cancelled')
                    return
                else
                    load( fullfile(pathname, filename),'cExperiment')
                end
                
            end
            CellResGUI.cExperiment = cExperiment;
            
            if isempty(cExperiment.cellInf)
                
                warndlg('please extract data before running the cellResultsViewingGUI (the clue is in the name)')
                uiwait
                return
                
            end
            
            CellResGUI.needToSave=false;
            scrsz = get(0,'ScreenSize');
            CellResGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(4) 2*scrsz(4)/3]);
            
            CellResGUI.TopPanel = uipanel('Parent',CellResGUI.figure,...
                'Position',[.015 .5575 .97 .4275 ]);
            CellResGUI.PlotPanel = uipanel('Parent',CellResGUI.figure,...
                'Position',[.015 .0615 .97 .4675]);
            
            CellResGUI.CellSelectListInterface = uicontrol(CellResGUI.TopPanel,'Style','listbox','String',{'no cells selected'},...
                'Units','normalized','Position',[.33 .015 .3 .97],'Max',1,'Min',1,'Callback',@(src,event)SelectCell(CellResGUI));
            
            CellResGUI.CellsForSelection = [cExperiment.cellInf(1).posNum(:) cExperiment.cellInf(1).trapNum(:) cExperiment.cellInf(1).cellNum(:)];

            CellResGUI.cExperiment.loadCurrentTimelapse(cExperiment.cellInf(1).posNum(1));
            
            if length(cExperiment.cellInf) ~= length(cExperiment.cTimelapse.channelNames)
                
                if ~isfield(cExperiment.cellInf,'extractionParameters')...
                        | ~isfield(cExperiment.cellInf(1).extractionParameters,'functionParameters') ...
                        | ~isfield(cExperiment.cellInf(1).extractionParameters.functionParameters,'channels')
                    
                dialog_struct = struct('title','Data Channel Assignment',...
                    'Description',['Please select which channels each dataset in the cellInf array corresponds to']);
                for ci = 1:length(cExperiment.cellInf)
                    
                    channel_name_fields{ci} = sprintf('sc%d',ci);
                    
                    dialog_struct.(sprintf('forgotten_field_%d',ci)) =...
                        struct('entry_name',...
                        {{sprintf('data set %d in cellInf',ci),channel_name_fields{ci}}},...
                        'entry_value',{cExperiment.cTimelapse.channelNames});
                end
                
                [settings, button] = settingsdlg(dialog_struct);
                
                if ~strcmp(button,'OK')
                    fprintf('\n GUI cancelled \n')
                    return
                end
                
                CellResGUI.ChannelDataCode = {};
                for channeli = 1:length(channel_name_fields)
                    
                    CellResGUI.ChannelDataCode{channeli} = settings.(sprintf('sc%d',channeli));
                    
                end
                else
                    if strcmp(cExperiment.cellInf(1).extractionParameters.functionParameters.channels,'all')
                        CellResGUI.ChannelDataCode = cExperiment.cTimelapse.channelNames;
                    else
                        CellResGUI.ChannelDataCode = cExperiment.cTimelapse.channelNames(cExperiment.cellInf(1).extractionParameters.functionParameters.channels);
                    end
                end
 
            else
                CellResGUI.ChannelDataCode = cExperiment.cTimelapse.channelNames;
            end
            
            CellResGUI.SettingsPanel = uipanel('Parent',CellResGUI.TopPanel,'Position',[.015 .015 .3 .97 ]);
            
            % call back for all these buttons set to be slider call back
            % since this renews all the image which is all that needs to
            % happen.
            
            settings_buttons = 4;
            setting_buttons_spacing = 0.015;
            
            setting_buttons_height = (1 - ((settings_buttons+1)*setting_buttons_spacing))/settings_buttons;
            
            y_bottom = setting_buttons_spacing;
            
                        uicontrol('Parent',CellResGUI.SettingsPanel,'Style','text','String','Plot Field',...
                'Units','normalized','Position',[.015 y_bottom .485 setting_buttons_height]);            
            CellResGUI.SelectPlotFieldButton = uicontrol('Parent',CellResGUI.SettingsPanel,'Style','popupmenu','String', fieldnames(cExperiment.cellInf),...
                'Units','normalized','Position',[.5 y_bottom .485 setting_buttons_height],'Callback',@(src,event)CellRes_slider_cb(CellResGUI));
            
            y_bottom = y_bottom+setting_buttons_height+setting_buttons_spacing;
            
            uicontrol('Parent',CellResGUI.SettingsPanel,'Style','text','String','Plot Channel',...
                'Units','normalized','Position',[.015 y_bottom .485 setting_buttons_height]);            
            CellResGUI.SelectPlotChannelButton = uicontrol('Parent',CellResGUI.SettingsPanel,'Style','popupmenu','String', CellResGUI.ChannelDataCode',...
                'Units','normalized','Position',[.5 y_bottom .485 setting_buttons_height],'Callback',@(src,event)CellRes_slider_cb(CellResGUI));
            
            y_bottom = y_bottom+setting_buttons_height+setting_buttons_spacing;
            
            uicontrol('Parent',CellResGUI.SettingsPanel,'Style','text','String','Image Channel',...
                'Units','normalized','Position',[.015 y_bottom .485 setting_buttons_height]);
            CellResGUI.SelectImageChannelButton = uicontrol('Parent',CellResGUI.SettingsPanel,'Style','popupmenu','String',CellResGUI.cExperiment.cTimelapse.channelNames',...
                'Units','normalized','Position',[.5 y_bottom .485 setting_buttons_height],'Callback',@(src,event)CellRes_slider_cb(CellResGUI));
            
            y_bottom = y_bottom+setting_buttons_height+setting_buttons_spacing;
            
            CellResGUI.ResetImageScaleButton = uicontrol('Parent',CellResGUI.SettingsPanel,'Style','pushbutton','String', 'Reset Image Scale',...
                'Units','normalized','Position',[.015 y_bottom .97 setting_buttons_height],'Callback',@(src,event)ResetImageScale(CellResGUI));
            
            CellResGUI.CellImageHandle = axes('Parent',CellResGUI.TopPanel,'Position',[.685 .015 .3 .97 ]);
            set(CellResGUI.CellImageHandle,'XTick',[]);
            set(CellResGUI.CellImageHandle,'YTick',[]);
            
            % activate and set image click functions.
            % due to the way imshow operates, the ButtonDownFcn will
            % actually get passed on the the image object when it gets
            % plotted in the CellRes_draw_cell callback.
            % not the smartest way to do things
            set(CellResGUI.CellImageHandle,'ButtonDownFcn',@(src,event)CellRes_image_click_cb(CellResGUI,src,event));
            set(CellResGUI.CellImageHandle,'HitTest','on'); 
                    
            CellResGUI.PlotHandle = axes('Parent',CellResGUI.PlotPanel,'Position',[.03 .05 .94 .9 ]);
            
            CellResGUI.slider=uicontrol('Style','slider',...
                'Parent',CellResGUI.figure,...
                'Min',CellResGUI.cExperiment.timepointsToProcess(1),...
                'Max',CellResGUI.cExperiment.timepointsToProcess(end),...
                'Units','normalized',...
                'Value',CellResGUI.cExperiment.timepointsToProcess(1),...
                'Position',[0.015 0.015 0.97 0.03],...
                'SliderStep',...
                [1/(length(CellResGUI.cExperiment.timepointsToProcess)-1) ...
                1/(max(round((CellResGUI.cExperiment.timepointsToProcess(end) - CellResGUI.cExperiment.timepointsToProcess(1))/10),1))],...
                'Callback',@CellResGUI.CellRes_slider_cb);
            addlistener(CellResGUI.slider,'Value','PostSet',@CellResGUI.CellRes_slider_cb);
            addlistener(CellResGUI.CellSelectListInterface,'Value','PostSet',@CellResGUI.SelectCell);

            set(CellResGUI.figure,'BusyAction','cancel');
            
            %scroll wheel function
            set(CellResGUI.figure,'WindowScrollWheelFcn',@CellResGUI.Generic_ScrollWheel_cb);
            
            %keydown function
            set(CellResGUI.figure,'WindowKeyPressFcn',@CellResGUI.CellRes_key_press_cb);
            
            CellResGUI.CellSelected = 0;
            set(CellResGUI.CellSelectListInterface,'Value',1);
            
            % make manual info
            CellResGUI.needToSave = CellResGUI.cExperiment.populateManualLineageInfo;
            CellResGUI.birthTypeUse = 'Manual';
            
            CellResGUI.SelectCell();
            
        end

        function CellResGUI = set.CellsForSelection(CellResGUI,setting_array)
            %set.CellsForSelection(CellResGUI,setting_cell) method for
            %setting the cells that the GUI allows you to select. Expects
            %an input array of the form 
            %     [position_array trap_array cell_number_array]
            %where the columns of the array are vectors of the position, trap
            %number and cell number of each cell to be viewable.
            
            
            if size(setting_array,2)~=3
                error('setting cell should be an array of the form \n\n     [position_array trap_array cell_number_array] \n\nwhere the columns of the array are vectors of the position, trapnumber and cell number of each cell to be viewable.')
            end
            
            if ~isnumeric(setting_array)
                error('setting cell should be an array of the form \n\n     [position_array trap_array cell_number_array] \n\nwhere the columns of the array are vectors of the position, trapnumber and cell number of each cell to be viewable.')
            end
            
            % this is a bit involved and is to make sure the right
            % cTimelapse gets loaded
            if CellResGUI.CellSelected~=0;
                set_cell = true;
                old_id = CellResGUI.CellsForSelection(CellResGUI.CellSelected,:);
            else
                set_cell = false;
            end
            
            CellResGUI.CellsForSelection = setting_array;
            CellResGUI.CellsforSelectionDiplayString = {};
            
            for celli =1:size(setting_array,1)
                
                CellResGUI.CellsforSelectionDiplayString{celli} = sprintf('%s   trap: %3d   cell:  %3d',CellResGUI.cExperiment.dirs{setting_array(celli,1)},setting_array(celli,2),setting_array(celli,3));
                
            end
            
            
            set(CellResGUI.CellSelectListInterface,'String',CellResGUI.CellsforSelectionDiplayString);
            if set_cell
                
                [cell_present,new_cell_id] = ismember(old_id,setting_array,'rows');
                if cell_present
                    CellResGUI.CellSelected = new_cell_id;
                    set(CellResGUI.CellSelectListInterface,'Value',new_cell_id);
                else
                    CellResGUI.CellSelected = 0;
                    set(CellResGUI.CellSelectListInterface,'Value',1);
                end
            
                    
                
            else
            set(CellResGUI.CellSelectListInterface,'Value',1);
            end
            
        end
        
        function setCellsWithLogical(CellResGUI,logical_of_cells)
        %function setCellsWithLogical(CellResGUI,logical)
        % set cells to look at as a subset of the whole of cExperiment just
        % by providing a logical or an index vector.
        
        CellResGUI.CellsForSelection = [CellResGUI.cExperiment.cellInf(1).posNum(logical_of_cells)' ...
                                        CellResGUI.cExperiment.cellInf(1).trapNum(logical_of_cells)'...
                                        CellResGUI.cExperiment.cellInf(1).cellNum(logical_of_cells)'];
        
        end
        
        function setCellsWithLogicalFromCellSelected(CellResGUI,logical_of_cells)
        %function setCellsWithLogicalFromCellSelected(CellResGUI,logical)
        % set cells to look at as a subset of the whole of those currently
        % selected. 
        
        CellResGUI.CellsForSelection = CellResGUI.CellsForSelection(logical_of_cells,:);
        
        end
        
        
        function setCellsAsMothers(CellResGUI)
        % setCellsAsMothers(CellResGUI)
        % sets the cells to only the mother cells of the cvells already selected.
        if ~isempty(CellResGUI.cExperiment.lineageInfo)
            
            mother_cell_logical = ismember(CellResGUI.CellsForSelection,...
                [CellResGUI.cExperiment.lineageInfo.motherInfo.motherPosNum' ...
                CellResGUI.cExperiment.lineageInfo.motherInfo.motherTrap' ...
                CellResGUI.cExperiment.lineageInfo.motherInfo.motherLabel'],'rows');
            
            setCellsWithLogicalFromCellSelected(CellResGUI,mother_cell_logical);
        else
            fprintf('\n\n  No Mother Info for this experiment \n\n')
        end
            
        end
        
        function setCellsToAll(CellResGUI)
        % setCellsToAll(CellResGUI)
        % returns selection to all cells in cExperiment

        setCellsWithLogical(CellResGUI,true(size(CellResGUI.cExperiment.cellInf(1).posNum)));
        
        end

        
    end
end