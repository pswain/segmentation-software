classdef experimentTrackingGUI<handle
    % EXPERIMENTTRACKINGGUI  gui for some of the experimentTracking
    % processing and display functions. 
    %
    % This GUI is used in conjection with the
    % STANDARD_CEXPERIMENT_PROCESSING_SCRIPT to process cExperiments. The
    % buttons on the left hand panel are for loading/creating experiments.
    % One should then use the processing script to complete automatically
    % identify and track cells. 
    % Once this is completed, the buttons on the right hand panel allow you
    % to view the results and edit/curate them.
    % 
    % The uses of the buttons are as follows:
    % 
    % Create New Experiment : create a new experiment object from images.
    % This is how the processing is started. The Omero sub button allows an
    % experiment to be created from the Omero Database.
    % 
    % Load Experiment File : this allows a cExperiment file that has
    % already been made to be loaded.
    % 
    % =====================================================================
    % The rest of the buttons are for post processing once the experiment
    % has been segmented 
    % =====================================================================
    % 
    % Channel : select a channel to view when opening a GUI (though the
    % channel can, for most GUI's, be changed by pressing up and down
    % arrows)
    %
    % View Timelapse : View the raw images from the timelapse.
    % 
    % Edit Segmentation : open a GUI for adding and removing cells.
    %
    % Auto Select : automatically select cells to extract data for. This
    % allows data to only be extracted for a sub set of the cells (such as
    % cells that are only there for a certain period) and thereby keep the
    % data structure manageable.
    %
    % Select Cells : open a GUI by which the cells to extract data for can
    % be manually selected/curated. This allows erroneous or uninteresting
    % cells to be excluded from the data structure.
    %
    % Extract Data : extracts data for the selected cells. Only needs to be
    % run after the script if the cells to be extracted has in some way
    % been modified.
    %
    % Compile Data : take the data extracted for each position and compile
    % them together in the cExperiment object. Essentially, collect
    % together the data for all positions into 1 huge data structure.
    % 
    % Extract Births Info : decides mother cells and extract birth events.
    % This uses the extracted data, and so only cells appearing in the
    % extracted data will be candidates for daughters or mothers.
    %
    % Open CellResGUI : opens a gui in which images of the cells and
    % the extracted data for those cells can be seen in one GUI. Can also
    % be used to curate birth events.
    % 
    % See also EXPERIMENTTRACKING, TIMELAPSETRAPS
    properties
        figure = [];
        expPanel
        processingPanel
        
        createExperimentButton
        createFromOmeroButton
        loadSavedExperimentButton
        %loadCellVisionButton
        posList
        %saveExperimentButton
        
        selectChannelText
        selectChannelButton
        
        
        %addSecondaryChannelButton
        displayWholeTimelapseButton
        %selectTrapsToProcessButton
       	%timepointsToProcessButton
        %cropTimepointsButton
        %identifyCellsButton
        %extractSegAreaFlButton
        editProcessedTimelapseButton
        %trackCellsButton
        %combineTrackletsButton
        extractBirthsButton
        
        autoSelectButton
        selectButton
        extractDataButton
        compileDataButton
        %RunActiveContourButton
        editSegmentationButton
        
        openCellResButton
        currentGUI;

        cExperiment;
        channel;
        gui_help = help('experimentTrackingGUI')
    end % properties
   
    methods
        function cExpGUI=experimentTrackingGUI(make_buttons)
            % cExpGUI=experimentTrackingGUI(make_buttons)
            % makes the cExpGUI
            % make_buttons tells it whether to make the standard buttons. Default is true. 
            
            if nargin<1 || isempty(make_buttons)
                make_buttons = true;
            end
            %Add Omero code to the path
            
            if ispc
                addpath(genpath('C:\Users\Public\OmeroCode'));
            else
                addpath(genpath(['/Users/' char(java.lang.System.getProperty('user.name')) '/Documents/Omero code']));
            end
            
            cExpGUI.channel=1;
            
            if make_buttons
            
            scrsz = get(0,'ScreenSize');
            cExpGUI.figure=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 scrsz(3)*3/8 scrsz(4)/2]);
            cExpGUI.expPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.015 .02 .73 .95 ]);
            cExpGUI.processingPanel = uipanel('Parent',cExpGUI.figure,...
                'Position',[.765 .02 .22 .95]);
            
            cExpGUI.createExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Create New Experiment',...
                'Units','normalized','Position',[.025 .85 .95 .15],'Callback',@(src,event)createExperiment(cExpGUI));
            thisPath=mfilename('fullpath');
            k=strfind(thisPath,'Matt Seg GUI');
            omeroIcon=imread([thisPath(1:k+12) 'OmeroIcon.jpg']);
            cExpGUI.createFromOmeroButton = uicontrol('Parent', cExpGUI.expPanel,'Style','pushbutton','CData',omeroIcon...
               ,'Units','normalized','Position',[.75 .87 .17 .11],'Callback',@(src,event)createFromOmero(cExpGUI),'TooltipString','Create, load, delete or archive an experiment in the Omero database');

            cExpGUI.loadSavedExperimentButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load Experiment File',...
                'Units','normalized','Position',[.025 .7 .95 .15],'Callback',@(src,event)loadSavedExperiment(cExpGUI));
%            cExpGUI.loadCellVisionButton = uicontrol(cExpGUI.expPanel,'Style','pushbutton','String','Load CellVision Model',...
%                'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)loadCellVision(cExpGUI));
            cExpGUI.posList = uicontrol(cExpGUI.expPanel,'Style','listbox','String',{'None Loaded'},...
                'Units','normalized','Position',[.025 .0 .95 .7],'Max',30,'Min',1);
            
%             cExpGUI.addSecondaryChannelButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Add Channel',...
%                 'Units','normalized','Position',[.025 .85 .47 .15],'Callback',@(src,event)addSecondaryChannel(cExpGUI));
             cExpGUI.displayWholeTimelapseButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','View Timelapse',...
                'Units','normalized','Position',[.025 .85 .95 .1],'Callback',@(src,event)displayWholeTimelapse(cExpGUI));
            cExpGUI.selectChannelText = uicontrol(cExpGUI.processingPanel,'Style','text','String','Channel',...
                'Units','normalized','Position',[.025 .95 .3 .05]);            
            cExpGUI.selectChannelButton = uicontrol(cExpGUI.processingPanel,'Style','popupmenu','String','None',...
                'Units','normalized','Position',[.35 .85 .6 .15],'Callback',@(src,event)selectChannel(cExpGUI));

%             cExpGUI.timepointsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Tp to Proc',...
%                 'Units','normalized','Position',[.505 .7 .47 .15],'Callback',@(src,event)timepointsToProcess(cExpGUI));
%            cExpGUI.selectTrapsToProcessButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Traps',...
%                'Units','normalized','Position',[.025 .75 .95 .1],'Callback',@(src,event)selectTrapsToProcess(cExpGUI));
           
%             cExpGUI.identifyCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Identify Cells',...
%                 'Units','normalized','Position',[.025 .55 .47 .15],'Callback',@(src,event)identifyCells(cExpGUI));

%             cExpGUI.trackCellsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Track Cells',...
%                 'Units','normalized','Position',[.025 .45 .47 .10],'Callback',@(src,event)trackCells(cExpGUI));
%            cExpGUI.combineTrackletsButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Combine Tracks',...
%                 'Units','normalized','Position',[.755 .55 .22 .15],'Callback',@(src,event)combineTracklets(cExpGUI));

             cExpGUI.editSegmentationButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Edit Segmentation',...
                'Units','normalized','Position',[.025 .75 .95 .1],'Callback',@(src,event)editSegmentationGUI(cExpGUI));
           
%             cExpGUI.extractSegAreaFlButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Get Fl Area',...
%                 'Units','normalized','Position',[.505 .55 .25 .15],'Callback',@(src,event)extractSegAreaFl(cExpGUI));
            
            cExpGUI.autoSelectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','AutoSelect',...
                'Units','normalized','Position',[.025 .65 .95 .10],'Callback',@(src,event)autoSelect(cExpGUI));
            cExpGUI.selectButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Select Cells',...
                'Units','normalized','Position',[.025 .55 .95 .10],'Callback',@(src,event)select(cExpGUI));

            cExpGUI.extractDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract Data',...
                'Units','normalized','Position',[.025 .45 .95 .10],'Callback',@(src,event)extractData(cExpGUI));
            cExpGUI.compileDataButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Compile Data',...
                'Units','normalized','Position',[.025 .35 .95 .10],'Callback',@(src,event)compileData(cExpGUI));
            cExpGUI.extractBirthsButton=uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Extract births info',...
                'Units','normalized','Position',[.025 .25 .95 .10],'Callback',@(src,event)extractBirths(cExpGUI),'TooltipString','Extract data on budding events undergone by mother cells');

            cExpGUI.openCellResButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Open CellResGUI',...
                'Units','normalized','Position',[.025 .15 .95 .10],'Callback',@(src,event)openCellResGUI(cExpGUI));

%             cExpGUI.RunActiveContourButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Run Active Contour',...
%                 'Units','normalized','Position',[.505 .25 .47 .10],'Callback',@(src,event)RunActiveContourEperimentGUI(cExpGUI));

%             cExpGUI.saveExperimentButton = uicontrol(cExpGUI.processingPanel,'Style','pushbutton','String','Save Experiment',...
%                 'Units','normalized','Position',[.025 .0 .47 .15],'Callback',@(src,event)saveExperiment(cExpGUI));
            
            set(cExpGUI.figure,'WindowKeyPressFcn',@(src,event)cExpGUI.keyPress_cb(src,event));
            
            
            end
        end
    end
end