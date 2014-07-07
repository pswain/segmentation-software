classdef experimentTrackingGUI<handle
    %ExperimeintTrackingGUI: Track and analyse multiple image sets
    %--------------------------
    %Track multiple timelapse images, normally different areas of the same
    %experiment
    %Each timelapse should be a series of images (not microscopy films) in
    %its own folder. The folders for these timelapses should be in a 
    %folder with NOTHING ELSE. A folder in this superfolder which does not
    %contain a timelapse will be read as a timelapse and cause a crash.
    properties
        figure = [];
        expPanel
        processingPanel
        
        prepDeltaVisionButton
        createExperimentButton
        loadSavedExperimentButton
        loadCellVisionButton
        posList
        saveExperimentButton
        
        addSecondaryChannelButton
        displayWholeTimelapseButton
        selectTrapsToProcessButton
       	timepointsToProcessButton
        cropTimepointsButton
        identifyCellsButton
        extractSegAreaFlButton
        processIndTimelapseButton
        editProcessedTimelapseButton
        trackCellsButton
        combineTrackletsButton
        
        autoSelectButton
        selectButton
        extractDataButton
        compileDataButton
        RunActiveContourButton
        
        currentGUI;

        cExperiment;
        cTimelapse=[]
        cCellVision=[];
        channel=1;
    end % properties
   
    methods
        function cExpGUI=experimentTrackingGUI()
            
            
            scrsz = get(0,'ScreenSize');
            cExpGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)/2 scrsz(4)/2]);
            
            cExpGUI.expPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.015 .02 .47 .95 ]);
            cExpGUI.processingPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.515 .02 .47 .95]);
            
             cExpGUI.prepDeltaVisionButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Convert .dv Files',...
                'Units','normalized','Position',[.025 .85 .47 .15],'Callback',@(src,event)PositionsFromDeltavision());
            cExpGUI.createExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','New Experiment',...
                'Units','normalized','Position',[.505 .85 .47 .15],'Callback',@(src,event)createExperiment(cExpGUI));
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
                'Units','normalized','Position',[.505 .85 .25 .15],'Callback',@(src,event)displayWholeTimelapse(cExpGUI));
            cExpGUI.timepointsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Tp to Proc',...
                'Units','normalized','Position',[.755 .85 .22 .15],'Callback',@(src,event)timepointsToProcess(cExpGUI));

            %
            cExpGUI.cropTimepointsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Crop Timepoints',...
                'Units','normalized','Position',[.025 .7 .235 .15],'Callback',@(src,event)cropTimepoints(cExpGUI));            
            cExpGUI.selectTrapsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Traps',...
                'Units','normalized','Position',[.265 .7 .23 .15],'Callback',@(src,event)selectTrapsToProcess(cExpGUI));
             cExpGUI.selectTrapsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Automatic Processing',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)automaticProcessing(cExpGUI));
            
            cExpGUI.identifyCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[.025 .55 .3 .15],'Callback',@(src,event)identifyCells(cExpGUI));
%             cExpGUI.extractSegAreaFlButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Get Fl Area',...
%                 'Units','normalized','Position',[.325 .55 .175 .15],'Callback',@(src,event)extractSegAreaFl(cExpGUI));

            cExpGUI.trackCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Track Cells',...
                'Units','normalized','Position',[.505 .55 .25 .15],'Callback',@(src,event)trackCells(cExpGUI));
            cExpGUI.combineTrackletsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Combine Tracks',...
                'Units','normalized','Position',[.755 .55 .22 .15],'Callback',@(src,event)combineTracklets(cExpGUI));

             cExpGUI.autoSelectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Edit Segmentation',...
                'Units','normalized','Position',[.325 .55 .175 .15],'Callback',@(src,event)editSegmentationGUI(cExpGUI));
           
            
            
            cExpGUI.autoSelectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','AutoSelect',...
                'Units','normalized','Position',[.025 .45 .47 .10],'Callback',@(src,event)autoSelect(cExpGUI));
            cExpGUI.selectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Cells',...
                'Units','normalized','Position',[.505 .45 .47 .10],'Callback',@(src,event)select(cExpGUI));

            cExpGUI.extractDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[.025 .25 .47 .15],'Callback',@(src,event)extractData(cExpGUI));
%             cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Compile Data',...
%                 'Units','normalized','Position',[.505 .25 .47 .15],'Callback',@(src,event)compileData(cExpGUI));
            cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Display Data',...
                'Units','normalized','Position',[.505 .25 .47 .15],'Callback',@(src,event)cellAsicAnalysis(cExpGUI));


            cExpGUI.processIndTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Process Ind Timelapse',...
                'Units','normalized','Position',[.505 .15 .47 .10],'Callback',@(src,event)processIndTimelapse(cExpGUI));
            
            cExpGUI.RunActiveContourButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Run Active Contour',...
                'Units','normalized','Position',[.025 .15 .47 .10],'Callback',@(src,event)RunActiveContourEperimentGUI(cExpGUI));
            
            
        end

        % Other functions 
        

        PositionsFromDeltaVision()
        createExperiment(cExpGUI)
        loadSavedExperiment(cExpGUI)
        loadCellVision(cExpGUI)
        
        
        addSecondaryChannel(cExpGUI)
        saveTimelapse(cExpGUI)
        cropTimepoints(cExpGUI)
        automaticProcessing(cExpGUI)
        
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
        cellAsicAnalysis(cExpGUI)
        compileData(cExpGUI)
        
        processIndTimelapse(cExpGUI)
    end
end