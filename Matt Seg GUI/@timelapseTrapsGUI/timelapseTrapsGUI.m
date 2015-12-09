classdef timelapseTrapsGUI<handle
    % timelapseTrapsGUI
    %
    % for editing individual timelapse. Not as well maintained as the
    % experimentTrackingGUI so better to use that one with a single
    % position selected.
    properties
        figure = [];
        timelapsePanel
        processingPanel
        
        loadSavedTimelapseButton
        loadCellVisionButton
        selectTimelapseButton   
        addSecondaryChannelButton
        cropTimelapseButton
        
        saveTimelapseButton
        
        selectChannelButton
        selectChannelText
        %         selectTrapTemplateButton=[];
        displayWholeTimelapseButton
        selectTrapsToProcessButton
        cropTimepointsButton
        identifyCellsButton
        editProcessedTimelapseButton
        trackCellsButton
        selectCellsPlotButton
        autoSelectButton
        extractDataButton
        ActiveContourButton
        
        currentGUI;

        cTimelapse=[]
        cCellVision=[];
        channel=1;
        
    end
    
    properties (SetObservable)
        ActiveContourButtonState = 1;
        
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cTrapsGUI=timelapseTrapsGUI(cTimelapse,cCellVision)
            
            
            
            if nargin<2
                cTrapsGUI.cCellVision=cellVision();
            else
                cTrapsGUI.cCellVision=cCellVision;
            end
            
            scrsz = get(0,'ScreenSize');
            cTrapsGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/3 scrsz(4)/3]);
            
            cTrapsGUI.timelapsePanel = uipanel('Parent',cTrapsGUI.figure,...
                'Position',[.015 .05 .47 .9 ]);
            cTrapsGUI.processingPanel = uipanel('Parent',cTrapsGUI.figure,...
                'Position',[.515 .05 .47 .75]);
            
            cTrapsGUI.addSecondaryChannelButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Add image channel',...
                'Units','normalized','Position',[.025 .55 .55 .15],'Callback',@(src,event)addSecondaryChannel(cTrapsGUI));
            cTrapsGUI.cropTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Crop Timepoints',...
                'Units','normalized','Position',[.575 .55 .4 .15],'Callback',@(src,event)cropTimepoints(cTrapsGUI));
            cTrapsGUI.loadCellVisionButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Load CellVision Model',...
                'Units','normalized','Position',[.025 .4 .95 .15],'Callback',@(src,event)loadCellVision(cTrapsGUI));
            cTrapsGUI.saveTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Save Timelapse',...
                'Units','normalized','Position',[.025 .0 .95 .2],'Callback',@(src,event)saveTimelapse(cTrapsGUI));
            
            cTrapsGUI.selectChannelText = uicontrol('Parent',cTrapsGUI.figure,'Style','text','String','Channel',...
                'Units','normalized','Position',[.515 .85 .2 .05]);            
            cTrapsGUI.selectChannelButton = uicontrol('Parent',cTrapsGUI.figure,'Style','popupmenu','String','None',...
                'Units','normalized','Position',[.715 .7 .27 .2],'Callback',@(src,event)selectChannel(cTrapsGUI));
            
            if nargin<1
                cTrapsGUI.selectTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Create New Timelapse',...
                    'Units','normalized','Position',[.025 .85 .95 .15],'Callback',@(src,event)selectTimelapse(cTrapsGUI));
                cTrapsGUI.loadSavedTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Load Timelapse File',...
                    'Units','normalized','Position',[.025 .7 .95 .15],'Callback',@(src,event)loadSavedTimelapse(cTrapsGUI));
            else
                cTrapsGUI.cTimelapse=cTimelapse;
                set(cTrapsGUI.selectChannelButton,'String',cTrapsGUI.cTimelapse.channelNames,'Value',1);
            end
            
            
            cTrapsGUI.displayWholeTimelapseButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Display Timelapse',...
                'Units','normalized','Position',[.025 .8 .95 .2],'Callback',@(src,event)displayWholeTimelapse(cTrapsGUI));
            cTrapsGUI.selectTrapsToProcessButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Select Traps',...
                'Units','normalized','Position',[.025 .6 .47 .2],'Callback',@(src,event)selectTrapsToProcess(cTrapsGUI));
            cTrapsGUI.identifyCellsButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[.505 .6 .47 .2],'Callback',@(src,event)identifyCells(cTrapsGUI));
            cTrapsGUI.editProcessedTimelapseButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Edit Timelapse',...
                'Units','normalized','Position',[.025 .4 .47 .2],'Callback',@(src,event)editProcessTimelapse(cTrapsGUI));
            cTrapsGUI.trackCellsButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Track cells',...
                'Units','normalized','Position',[.505 .4 .47 .2],'Callback',@(src,event)trackCells(cTrapsGUI));
            cTrapsGUI.selectCellsPlotButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Select cells to plot',...
                'Units','normalized','Position',[.025 .2 .65 .2],'Callback',@(src,event)selectCellsPlot(cTrapsGUI));
            cTrapsGUI.autoSelectButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','AutoSelect',...
                'Units','normalized','Position',[.68 .2 .295 .2],'Callback',@(src,event)autoSelect(cTrapsGUI));
            cTrapsGUI.ActiveContourButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Inst. Active Cont.',...
                'Units','normalized','Position',[.68 .0 .295 .2],'Callback',@(src,event)ActiveContourButtonTimelapseTrapsGUI(cTrapsGUI));
            cTrapsGUI.ActiveContourButtonState = 1;
            
            addlistener(cTrapsGUI,'ActiveContourButtonState','PostSet',@(src,event)changeActiveContourButtonState(cTrapsGUI));
            % this listener watches for changes to the
            % ActiveContourButtonState. Basically what happens is that the
            % object is instantiated, this sees, then the button is changed
            % to 'run'.
            %This allows you to play with the parameters between
            %instantiation and running.

            cTrapsGUI.extractDataButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[.025 .0 .65 .2],'Callback',@(src,event)extractData(cTrapsGUI));
            
        end

        % Other functions 
        

        
        selectTimelapse(cTrapsGUI)
        loadSavedTimelapse(cTrapsGUI)
        loadCellVision(cTrapsGUI)
        addSecondaryChannel(cTrapsGUI)
        saveTimelapse(cTrapsGUI)
        cropTimepoints(cTrapsGUI)
        
        selectChannel(cTrapsGUI)

        displayWholeTimelapse(cTrapsGUI)
        selectTrapsToProcess(cTrapsGUI)
        identifyCells(cTrapsGUI)
        editProcessTimelapse(cTrapsGUI)
        trackCells(cTrapsGUI)
        selectCellsPlot(cTrapsGUI)
        autoSelect(cTrapsGUI)
        extractData(cTrapsGUI)
    end
end