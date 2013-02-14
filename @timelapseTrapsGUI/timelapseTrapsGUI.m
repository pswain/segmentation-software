classdef timelapseTrapsGUI<handle
    properties
        figure = [];
        timelapsePanel
        processingPanel
        
        loadSavedTimelapseButton
        loadCellVisionButton
        selectTimelapseButton   
        saveTimelapseButton

%         selectTrapTemplateButton=[];
        selectTrapsToProcessButton
        cropTimepointsButton
        identifyCellsButton
        editProcessedTimelapseButton
        trackCellsButton
        selectCellsPlotButton

        cTimelapse=[]
        cCellVision=[];
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cTrapsGUI=timelapseTrapsGUI()
            scrsz = get(0,'ScreenSize');
            cTrapsGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/4 scrsz(4)/3]);
            
            cTrapsGUI.timelapsePanel = uipanel('Parent',cTrapsGUI.figure,...
                'Title','Timelapse Processing','Position',[.025 .05 .45 .9 ]);
            cTrapsGUI.processingPanel = uipanel('Parent',cTrapsGUI.figure,...
                'Title','cCellVision Processing','Position',[.525 .05 .45 .9]);
            
            cTrapsGUI.selectTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Create Timelapse From Images',...
                'Units','normalized','Position',[.025 .8 .95 .2],'Callback',@(src,event)selectTimelapse(cTrapsGUI));
            cTrapsGUI.loadSavedTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Load Timelapse File',...
                'Units','normalized','Position',[.025 .6 .95 .2],'Callback',@(src,event)loadSavedTimelapse(cTrapsGUI));
            cTrapsGUI.loadCellVisionButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Load CellVision Model',...
                'Units','normalized','Position',[.025 .4 .95 .2],'Callback',@(src,event)loadCellVision(cTrapsGUI));
            cTrapsGUI.saveTimelapseButton = uicontrol(cTrapsGUI.timelapsePanel,'Style','pushbutton','String','Save Timelapse',...
                'Units','normalized','Position',[.025 .0 .95 .2],'Callback',@(src,event)saveTimelapse(cTrapsGUI));
            
            cTrapsGUI.selectTrapsToProcessButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Select Traps to Track',...
                'Units','normalized','Position',[.025 .8 .95 .2],'Callback',@(src,event)selectTrapsToProcess(cTrapsGUI));
            cTrapsGUI.identifyCellsButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[.025 .6 .95 .2],'Callback',@(src,event)identifyCells(cTrapsGUI));
            cTrapsGUI.editProcessedTimelapseButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Edit the Timelapse',...
                'Units','normalized','Position',[.025 .4 .95 .2],'Callback',@(src,event)editProcessTimelapse(cTrapsGUI));
            cTrapsGUI.trackCellsButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Track identified cells',...
                'Units','normalized','Position',[.025 .2 .95 .2],'Callback',@(src,event)trackCells(cTrapsGUI));
            cTrapsGUI.selectCellsPlotButton = uicontrol(cTrapsGUI.processingPanel,'Style','pushbutton','String','Select cell to plot',...
                'Units','normalized','Position',[.025 .0 .95 .2],'Callback',@(src,event)selectCellsPlot(cTrapsGUI));

            
            cTrapsGUI.cCellVision=cellVision();
            
        end

        % Other functions 
        

        
        selectTimelapse(cTrapsGUI)
        loadSavedTimelapse(cTrapsGUI)
        loadCellVision(cTrapsGUI)
        saveTimelapse(cTrapsGUI)

        selectTrapsToProcess(cTrapsGUI)
        identifyCells(cTrapsGUI)
        editProcessTimelapse(cTrapsGUI)
        trackCells(cTrapsGUI)
        selectCellsPlot(cTrapsGUI)
    end
end