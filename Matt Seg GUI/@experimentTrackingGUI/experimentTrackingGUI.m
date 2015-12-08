classdef experimentTrackingGUI<handle
    properties
        figure = [];
        expPanel
        processingPanel
        
        createExperimentButton
        createFromOmeroButton
        loadSavedExperimentButton
        loadCellVisionButton
        posList
        saveExperimentButton
        
        selectChannelText
        selectChannelButton
        
        
        addSecondaryChannelButton
        displayWholeTimelapseButton
        selectTrapsToProcessButton
       	timepointsToProcessButton
        cropTimepointsButton
        identifyCellsButton
        extractSegAreaFlButton
        editProcessedTimelapseButton
        trackCellsButton
        combineTrackletsButton
        extractBirthsButton
        
        autoSelectButton
        selectButton
        extractDataButton
        compileDataButton
        RunActiveContourButton
        editSegmentationButton
        
        openCellResButton
        currentGUI;

        cExperiment;
        cTimelapse=[]
        cCellVision=[];
        channel;
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cExpGUI=experimentTrackingGUI()
            
            %Add Omero code to the path
            if ispc
                addpath(genpath('C:\Omero code\Omero code'));
            else
                addpath(genpath(['/Users/' char(java.lang.System.getProperty('user.name')) '/Documents/Omero code']));
            end
            
            cExpGUI.channel=1;

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
               ,'Units','normalized','Position',[.75 .87 .17 .11],'Callback',@(src,event)createFromOmero(cExpGUI),'TooltipString','Create experiment from Omero dataset');

            cExpGUI.loadSavedExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load Experiment File',...
                'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)loadSavedExperiment(cExpGUI));
            cExpGUI.loadCellVisionButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load CellVision Model',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)loadCellVision(cExpGUI));
            cExpGUI.posList = uicontrol(cExpGUI.expPanel,'Style','listbox','String',{'None Loaded'},...
                'Units','normalized','Position',[.025 .0 .95 .7],'Max',30,'Min',1);
            
            
            cExpGUI.addSecondaryChannelButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Add Channel',...
                'Units','normalized','Position',[.025 .85 .47 .15],'Callback',@(src,event)addSecondaryChannel(cExpGUI));
            cExpGUI.displayWholeTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Disp Timelapse',...
                'Units','normalized','Position',[.505 .85 .47 .1],'Callback',@(src,event)displayWholeTimelapse(cExpGUI));
            cExpGUI.selectChannelText = uicontrol(cExpGUI.processingPanel,'Style','text','String','Channel',...
                'Units','normalized','Position',[.515 .95 .22 .05]);            
            cExpGUI.selectChannelButton = uicontrol(cExpGUI.processingPanel,'Style','popupmenu','String','None',...
                'Units','normalized','Position',[.715 .85 .28 .15],'Callback',@(src,event)selectChannel(cExpGUI));

            cExpGUI.timepointsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Tp to Proc',...
                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)timepointsToProcess(cExpGUI));
            cExpGUI.selectTrapsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Traps',...
                'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)selectTrapsToProcess(cExpGUI));


            %
%             cExpGUI.cropTimepointsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Crop Timepoints',...
%                 'Units','normalized','Position',[.025 .7 .47 .15],'Callback',@(src,event)cropTimepoints(cExpGUI));            
            cExpGUI.identifyCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
                'Units','normalized','Position',[.025 .55 .47 .15],'Callback',@(src,event)identifyCells(cExpGUI));

            cExpGUI.trackCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Track Cells',...
                'Units','normalized','Position',[.025 .45 .47 .10],'Callback',@(src,event)trackCells(cExpGUI));
            cExpGUI.combineTrackletsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Combine Tracks',...
                'Units','normalized','Position',[.755 .55 .22 .15],'Callback',@(src,event)combineTracklets(cExpGUI));

             cExpGUI.editSegmentationButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Edit Segmentation',...
                'Units','normalized','Position',[.505 .45 .47 .1],'Callback',@(src,event)editSegmentationGUI(cExpGUI));
           
            cExpGUI.extractSegAreaFlButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Get Fl Area',...
                'Units','normalized','Position',[.505 .55 .25 .15],'Callback',@(src,event)extractSegAreaFl(cExpGUI));
% [.505 .45 .47 .1]
            
            cExpGUI.autoSelectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','AutoSelect',...
                'Units','normalized','Position',[.025 .35 .47 .10],'Callback',@(src,event)autoSelect(cExpGUI));
            cExpGUI.selectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Cells',...
                'Units','normalized','Position',[.505 .35 .47 .10],'Callback',@(src,event)select(cExpGUI));

            cExpGUI.extractDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[.025 .25 .47 .10],'Callback',@(src,event)extractData(cExpGUI));
            cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Compile Data',...
                'Units','normalized','Position',[.025 .15 .47 .10],'Callback',@(src,event)compileData(cExpGUI));

            cExpGUI.openCellResButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Open CellResGUI',...
                'Units','normalized','Position',[.505 .15 .47 .10],'Callback',@(src,event)openCellResGUI(cExpGUI));
            
            %,'BackgroundColor',[.6 .6 .6]
            cExpGUI.RunActiveContourButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Run Active Contour',...
                'Units','normalized','Position',[.505 .25 .47 .10],'Callback',@(src,event)RunActiveContourEperimentGUI(cExpGUI));

            cExpGUI.saveExperimentButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Save Experiment',...
                'Units','normalized','Position',[.025 .0 .47 .15],'Callback',@(src,event)saveExperiment(cExpGUI));

            cExpGUI.extractBirthsButton=uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract births info',...
                'Units','normalized','Position',[.505 .0 .47 .15],'Callback',@(src,event)extractBirths(cExpGUI),'TooltipString','Extract data on budding events undergone by mother cells');

        end

    end
end