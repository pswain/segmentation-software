classdef cellResultsViewingGUI<handle
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
        
    end % properties

    methods
        function CellResGUI=cellResultsViewingGUI(cExperiment)
            % CellResGUI=cellResultsViewingGUI(cExperiment) a GUI for
            % viewing the data extracted for single cells along with the
            % images of those cells at particular timepoints. Intended to
            % be used for checking data for obvious tracking errors and
            % such.
            
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

            scrsz = get(0,'ScreenSize');
            CellResGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(4) 2*scrsz(4)/3]);
            
            CellResGUI.TopPanel = uipanel('Parent',CellResGUI.figure,...
                'Position',[.015 .5575 .97 .4275 ]);
            CellResGUI.PlotPanel = uipanel('Parent',CellResGUI.figure,...
                'Position',[.015 .0615 .97 .4675]);
            
            CellResGUI.CellSelectListInterface = uicontrol(CellResGUI.TopPanel,'Style','listbox','String',{'no cells selected'},...
                'Units','normalized','Position',[.33 .015 .3 .97],'Max',1,'Min',1,'Callback',@(src,event)SelectCell(CellResGUI));
            
            CellResGUI.CellsForSelection = [cExperiment.cellInf(1).posNum' cExperiment.cellInf(1).trapNum' cExperiment.cellInf(1).cellNum'];
            
            CellResGUI.cExperiment.loadCurrentTimelapse(cExperiment.cellInf(1).posNum(1));
            
            if length(cExperiment.cellInf) ~= length(cExperiment.cTimelapse.channelNames)
                
                
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
            CellResGUI.CellImageHandle.XTick = [];
            CellResGUI.CellImageHandle.YTick = [];
            
            
            CellResGUI.PlotHandle = axes('Parent',CellResGUI.PlotPanel,'Position',[.03 .05 .94 .9 ]);
            
            CellResGUI.slider=uicontrol('Style','slider',...
                'Parent',CellResGUI.figure,...
                'Min',CellResGUI.cExperiment.timepointsToProcess(1),...
                'Max',CellResGUI.cExperiment.timepointsToProcess(end),...
                'Units','normalized',...
                'Value',CellResGUI.cExperiment.timepointsToProcess(1),...
                'Position',[0.015 0.015 0.97 0.03],...
                'SliderStep',...
                [1 max(round((CellResGUI.cExperiment.timepointsToProcess(end) - CellResGUI.cExperiment.timepointsToProcess(1))/10),1)],...
                'Callback',@(src,event)CellRes_slider_cb(CellResGUI));
            addlistener(CellResGUI.slider,'Value','PostSet',@(src,event)CellRes_slider_cb(CellResGUI));
            addlistener(CellResGUI.CellSelectListInterface,'Value','PostSet',@(src,event)SelectCell(CellResGUI));

            %scroll wheel function
            set(CellResGUI.figure,'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(CellResGUI,src,event));
            
            %keydown function
            set(CellResGUI.figure,'WindowKeyPressFcn',@(src,event)CellRes_key_press_cb(CellResGUI,src,event));

            %CellResGUI.SelectCell();
            
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
            
            CellResGUI.CellsForSelection = setting_array;
            CellResGUI.CellsforSelectionDiplayString = {};
            
            for celli =1:size(setting_array,1)
                
                CellResGUI.CellsforSelectionDiplayString{celli} = sprintf('%3d  %3d  %3d',setting_array(celli,1),setting_array(celli,2),setting_array(celli,3));
                
            end
            
            set(CellResGUI.CellSelectListInterface,'String',CellResGUI.CellsforSelectionDiplayString);
            set(CellResGUI.CellSelectListInterface,'Value',1);
            
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