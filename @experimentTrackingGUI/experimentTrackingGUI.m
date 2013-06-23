classdef experimentTrackingGUI<handle
    properties
        figure = [];
        expPanel
        processingPanel
        
        createExperimentButton
        loadSavedExperimentButton
        loadCellVisionButton
        posList
        saveExperimentButton
        
        addSecondaryChannelButton
        displayWholeTimelapseButton
        selectTrapsToProcessButton
        cropTimepointsButton
        identifyCellsButton
        processIndTimelapseButton
        editProcessedTimelapseButton
        trackCellsButton
        
        autoSelectButton
        selectButton
        extractDataButton
        compileDataButton
        
        currentGUI;

        cExperiment;
        cTimelapse=[]
        cCellVision=[];
        channel=1;
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cExpGUI=experimentTrackingGUI()
            
            
            scrsz = get(0,'ScreenSize');
            cExpGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/3 scrsz(4)/3]);
            
            cExpGUI.expPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.015 .02 .47 .95 ]);
            cExpGUI.processingPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.515 .02 .47 .95]);
            
            cExpGUI.createExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Create New Experiment',...
                'Units','normalized','Position',[.025 .85 .95 .15],'Callback',@(src,event)createExperiment(cExpGUI));
            cExpGUI.loadSavedExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load Experiment File',...
                'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)loadSavedExperiment(cExpGUI));
            cExpGUI.loadCellVisionButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load CellVision Model',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)loadCellVision(cExpGUI));
            cExpGUI.posList = uicontrol(cExpGUI.expPanel,'Style','listbox','String',{'None Loaded'},...
                'Units','normalized','Position',[.025 .0 .95 .7],'Max',30,'Min',1);

            cExpGUI.saveExperimentButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Save Experiment',...
                'Units','normalized','Position',[.025 .0 .95 .15],'Callback',@(src,event)saveExperiment(cExpGUI));
            
            
            cExpGUI.addSecondaryChannelButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Add Channel',...
                'Units','normalized','Position',[.025 .85 .47 .15],'Callback',@(src,event)addSecondaryChannel(cExpGUI));
            cExpGUI.displayWholeTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Disp Timelapse',...
                'Units','normalized','Position',[.505 .85 .47 .15],'Callback',@(src,event)displayWholeTimelapse(cExpGUI));

            %
            cExpGUI.cropTimepointsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Crop Timepoints',...
                'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)cropTimepoints(cExpGUI));            
            cExpGUI.selectTrapsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Traps',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)selectTrapsToProcess(cExpGUI));
            cExpGUI.identifyCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[.025 .55 .47 .15],'Callback',@(src,event)identifyCells(cExpGUI));
            cExpGUI.trackCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Track Cells',...
                'Units','normalized','Position',[.505 .55 .47 .15],'Callback',@(src,event)trackCells(cExpGUI));

            cExpGUI.autoSelectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','AutoSelect',...
                'Units','normalized','Position',[.025 .4 .47 .15],'Callback',@(src,event)autoSelect(cExpGUI));
            cExpGUI.selectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Cells',...
                'Units','normalized','Position',[.505 .4 .47 .15],'Callback',@(src,event)select(cExpGUI));

            cExpGUI.extractDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[.025 .25 .47 .15],'Callback',@(src,event)extractData(cExpGUI));
            cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Compile Data',...
                'Units','normalized','Position',[.505 .25 .47 .15],'Callback',@(src,event)compileData(cExpGUI));

            cExpGUI.processIndTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Process Ind Timelapse',...
                'Units','normalized','Position',[.505 .15 .47 .10],'Callback',@(src,event)processIndTimelapse(cExpGUI));
            
            
        end

        % Other functions 
        

        
        createExperiment(cExpGUI)
        loadSavedExperiment(cExpGUI)
        loadCellVision(cExpGUI)
        
        
        addSecondaryChannel(cExpGUI)
        saveTimelapse(cExpGUI)
        cropTimepoints(cExpGUI)
        
        selectChannel(cExpGUI)

        displayWholeTimelapse(cExpGUI)
        
        selectTrapsToProcess(cExpGUI)
        identifyCells(cExpGUI)
        editProcessTimelapse(cExpGUI)
        trackCells(cExpGUI)
        selectCellsPlot(cExpGUI)
        autoSelect(cExpGUI)
        select(cExpGUI)
        extractData(cExpGUI)
        compileData(cExpGUI)
        
        processIndTimelapse(cExpGUI)
    end
end