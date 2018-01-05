classdef experimentTrackingSlidesGUI < experimentTrackingGUI
    % EXPERIMENTTRACKINGSLIDESGUI This is a subclass of the
    % experimentTrackingGUI designed especially for slides to try and do
    % away with some of the problems of the experimenttrackingGUI when you
    % only have one timepoint and don't nececessarily want to actually
    % identify cells. 
    % Works in largely the same way with a reduced functionality. The edit
    % segmentation GUI is replaced with the curate tracking GUI (allows
    % outlines to be modified) and the identify cells does the active
    % contour method. 
    % tracking of traps and cells is automatically taken care of.
    properties
        loadCellVisionButton
        identifyCellsButton
        addSecondaryChannelButton
        
    end
    methods
        function cExpGUI = experimentTrackingSlidesGUI(make_buttons)
            % cExpGUI = experimentTrackingSlidesGUI(make_buttons)
            % makes the cExpGUI
            % make_buttons tells it whether to make the standard buttons. Default is true. 
            
            if nargin<1 || isempty(make_buttons)
                make_buttons = true;
            end
            
            cExpGUI = cExpGUI@experimentTrackingGUI(false);
            
            if make_buttons
                cExpGUI.makeButtons();
            end
            
        end
        
        function cExpGUI = makeButtons(cExpGUI)
            % cExpGUI = makeButtons(cExpGUI)
            % makes different set of buttons to standard experimentTrackingGUI
            % function calls are the same (though some are shadowed by new
            % methods).
            
            scrsz = get(0,'ScreenSize');
            cExpGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/2 scrsz(4)/2]);
            cExpGUI.expPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.015 .02 .47 .95 ]);
            cExpGUI.processingPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.515 .02 .47 .95]);
            
            cExpGUI.createExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Create New Experiment',...
                'Units','normalized','Position',[.025 .85 .95 .15],'Callback',@(src,event)createExperiment(cExpGUI));
            thisPath=mfilename('fullpath');
            k=strfind(thisPath,'Matt Seg GUI');
            omeroIcon=imread([thisPath(1:k+12) 'OmeroIcon.jpg']);
            cExpGUI.createFromOmeroButton = uicontrol('Parent', cExpGUI.expPanel,'Style','pushbutton','CData',omeroIcon...
               ,'Units','normalized','Position',[.75 .87 .17 .11],'Callback',@(src,event)createFromOmero(cExpGUI),'TooltipString','Create, load, delete or archive an experiment in the Omero database');

            cExpGUI.loadSavedExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load Experiment File',...
                'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)loadSavedExperiment(cExpGUI));
            cExpGUI.loadCellVisionButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load CellVision Model',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)loadCellVision(cExpGUI));
            cExpGUI.posList = uicontrol(cExpGUI.expPanel,'Style','listbox','String',{'None Loaded'},...
                'Units','normalized','Position',[.025 .0 .95 .7],'Max',30,'Min',1);

            
            % processing panel
            button_width = 0.95;
            top = 1.0;
            button_height = 0.15;
            button_space_v = 0.02;
            button_space_h = 0.025;
            button_total_v = button_height+button_space_v;
            current_top = top - button_height;
            
            cExpGUI.addSecondaryChannelButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Add Channel',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)addSecondaryChannel(cExpGUI));
            
            current_top = current_top - button_total_v;
            
            cExpGUI.displayWholeTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Disp Timelapse',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)displayWholeTimelapse(cExpGUI));

            current_top = current_top - button_total_v;
            % uncomment when we have a cellVision model.
            
            cExpGUI.identifyCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)identifyCells(cExpGUI));

            current_top = current_top - button_total_v;
            
            cExpGUI.editSegmentationButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Edit Segmentation',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)editSegmentationGUI(cExpGUI));
           
            current_top = current_top - button_total_v;
            
            cExpGUI.extractDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)extractData(cExpGUI));
            
            current_top = current_top - button_total_v;
            
            cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Compile Data',...
                'Units','normalized','Position',[button_space_h current_top  button_width button_height],'Callback',@(src,event)compileData(cExpGUI));


        end

        
        function createExperiment(cExpGUI)
            % createExperiment(cExpGUI)
            cExpGUI.cExperiment=experimentTracking();
            
            % createTimelapsePositions given with explicit arguments so that
            % magnification and imScale are not set in the GUI. These are generally
            % confusing arguments that are not widely used and necessarily supported.
            % This way they will not be used until again supported and
           cExpGUI.cExperiment.createTimelapsePositions([],'all',[],[],[],false);

            
            set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
            set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);

            cExpGUI.cExperiment.trackTrapsInTime;
            cExpGUI.cExperiment.saveExperiment;
        end
        
        
        function identifyCells(cExpGUI)
            % identifyCells(cExpGUI)
            % actually does the active contour method on first time point.
            poses = get(cExpGUI.posList,'Value');
            
            % set active contour channel to first cell identification
            % channel. Should usually work ok for standard brightfield
            % classifier.
            cTimelapse = cExpGUI.cExperiment.loadCurrentTimelapse(poses(1));
            cExpGUI.cExperiment.ActiveContourParameters.ImageTransformation.channel = cTimelapse.channelsForSegment(1);
            %cExpGUI.cExperiment.setSegmentationChannels;
            cExpGUI.cExperiment.RunActiveContourExperimentTracking(poses,1,1,true,1,false,false);

        end
        
        
    end
    
end

