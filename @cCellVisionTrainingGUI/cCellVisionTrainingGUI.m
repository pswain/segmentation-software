classdef cCellVisionTrainingGUI<handle
    properties
        figure = [];
        timelapsePanel
        cellVisionPanel
        loadTimelapseButton
        selectTimelapseButton
        selectTrapTemplateButton=[];
        selectTrapsForGroundTruthButton
        cropTimepointsButton
        saveTimelapseButton
        createGroundTruthButton
        
        trainStageOneButton
        trainStageTwoButton
        saveCellVisionButton
        setCellVisionTypeMenu
        setCellVisionTypeText
        setMinRadiusMenu
        setMinRadiusText
        setMaxRadiusMenu
        setMaxRadiusText
        setPixelSizeMenu
        setPixelSizeText
        setNegTrainingNumMenu
        setNegTrainingNumText

        cTimelapse=[]
        cCellVision=[];
    end % properties
    %% Displays timelapse for a single trap
    %This can either dispaly the primary channel (DIC) or a secondary channel
    %that has been loaded. It uses the trap positions identified in the DIC
    %image to display either the primary or secondary information.
    methods
        function cCellVisionGUI=cCellVisionTrainingGUI()
            
            cCellVisionGUI.figure=figure('MenuBar','none');
            cCellVisionGUI.cCellVision=cellVision();
            
            cCellVisionGUI.timelapsePanel = uipanel('Parent',cCellVisionGUI.figure,...
                'Title','Timelapse Processing','Position',[.01 .65 .98 .34]);
            cCellVisionGUI.cellVisionPanel = uipanel('Parent',cCellVisionGUI.figure,...
                'Title','cCellVision Processing','Position',[.01 .01 .98 .63]);
            
            cCellVisionGUI.selectTimelapseButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Load Timelapse Images',...
                'Units','normalized','Position',[.025 .75 .45 .25],'Callback',@(src,event)selectTimelapse(cCellVisionGUI));
            cCellVisionGUI.loadTimelapseButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Load Timelapse Class',...
                'Units','normalized','Position',[.025 .50 .45 .25],'Callback',@(src,event)loadSavedTimelapse(cCellVisionGUI));
            cCellVisionGUI.saveTimelapseButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Save Timelapse',...
                'Units','normalized','Position',[.025 .0 .45 .25],'Callback',@(src,event)saveTimelapse(cCellVisionGUI));
            
            cCellVisionGUI.selectTrapTemplateButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Select Trap Template',...
                'Units','normalized','Position',[.525 .75 .45 .25],'Callback',@(src,event)selectTrapTemplate(cCellVisionGUI));
            cCellVisionGUI.selectTrapsForGroundTruthButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Select Traps to Track',...
                'Units','normalized','Position',[.525 .50 .45 .25],'Callback',@(src,event)selectTrapsForGroundTruth(cCellVisionGUI));
            cCellVisionGUI.cropTimepointsButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Crop Timelpoints',...
                'Units','normalized','Position',[.525 .25 .45 .25],'Callback',@(src,event)cropTimepoints(cCellVisionGUI));
            cCellVisionGUI.createGroundTruthButton = uicontrol(cCellVisionGUI.timelapsePanel,'Style','pushbutton','String','Create Ground/Truth',...
                'Units','normalized','Position',[.525 .0 .45 .25],'Callback',@(src,event)createGroundTruth(cCellVisionGUI));
            
            cCellVisionGUI.trainStageOneButton = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','pushbutton','String','Train Stage One',...
                'Units','normalized','Position',[.025 .66 .65 .3],'Callback',@(src,event)trainCellVisionStageOne(cCellVisionGUI));
            cCellVisionGUI.trainStageTwoButton = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','pushbutton','String','Train Stage Two',...
                'Units','normalized','Position',[.025 .33 .65 .3],'Callback',@(src,event)trainCellVisionStageTwo(cCellVisionGUI));
            cCellVisionGUI.saveCellVisionButton = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','pushbutton','String','Save cCellVision',...
                'Units','normalized','Position',[.025 .03 .65 .3],'Callback',@(src,event)saveCellVision(cCellVisionGUI));
          
            cCellVisionGUI.setPixelSizeMenu = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','edit','String','0',...
                'Units','normalized','Position',[.7 .85 .275 .10],'Callback',@(src,event)setPixelSize(cCellVisionGUI));
            set(cCellVisionGUI.setPixelSizeMenu,'TooltipString','This is the size of camera pixels (microns) with current objective');
            cCellVisionGUI.setPixelSizeText = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','text','String','Camera Pixel Size',...
                'Units','normalized','Position',[.7 .96 .275 .05]);

            
            
            cCellVisionGUI.setMinRadiusMenu = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','popupmenu','String','4|5|6|7|8|9|10|11|12|13',...
                'Units','normalized','Position',[.7 .6 .275 .15],'Callback',@(src,event)setMinRadius(cCellVisionGUI));
            set(cCellVisionGUI.setMinRadiusMenu,'Value',2);
            set(cCellVisionGUI.setMinRadiusMenu,'TooltipString','This is the minimum radius of yeast cells to look for');
            cCellVisionGUI.setMinRadiusText = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','text','String','Min Radius',...
                'Units','normalized','Position',[.7 .76 .275 .05]);
            
            cCellVisionGUI.setMaxRadiusMenu = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','popupmenu','String','14|15|16|17|18|19|20|21|22|23|24|25|26|27',...
                'Units','normalized','Position',[.7 .4 .275 .15],'Callback',@(src,event)setMaxRadius(cCellVisionGUI));
            set(cCellVisionGUI.setMaxRadiusMenu,'Value',4);
            set(cCellVisionGUI.setMaxRadiusMenu,'TooltipString','This is the maximum radius of yeast cells to look for');
            cCellVisionGUI.setMaxRadiusText = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','text','String','Max Radius',...
                'Units','normalized','Position',[.7 .56 .275 .05]);

            cCellVisionGUI.setNegTrainingNumMenu = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','popupmenu','String','100|500|1,000|2,000|3,000|4,000|5,000|7,500|10,000|15,000',...
                'Units','normalized','Position',[.7 .2 .275 .15],'Callback',@(src,event)setNegTrainingNum(cCellVisionGUI));
            set(cCellVisionGUI.setNegTrainingNumMenu,'TooltipString','This is the number of negative training points to use from each image during training.');
            set(cCellVisionGUI.setNegTrainingNumMenu,'Value',2);
            cCellVisionGUI.setNegTrainingNumText = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','text','String','Num Neg Training',...
                'Units','normalized','Position',[.7 .36 .275 .05]);

            
            cCellVisionGUI.setCellVisionTypeMenu = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','popupmenu','String','Linear|Kernel|Two-Stage',...
                'Units','normalized','Position',[.7 .0 .275 .15],'Callback',@(src,event)setCellVisionType(cCellVisionGUI));
            cCellVisionGUI.setCellVisionTypeText = uicontrol(cCellVisionGUI.cellVisionPanel,'Style','text','String','Comp Vision Type',...
                'Units','normalized','Position',[.7 .16 .275 .05]);
            
            cCellVisionGUI.cCellVision=cellVision();
            
        end

        % Other functions 
        selectTimelapse(cCellVisionGUI)
        loadSavedTimelapse(cCellVisionGUI)
        saveTimelapse(cCellVisionGUI)
        selectTrapTemplate(cCellVisionGUI)
        selectTrapsForGroundTruth(cCellVisionGUI)
        cropTimepoints(cCellVisionGUI)
        createGroundTruth(cCellVisionGUI)
        
        trainCellVisionStageOne(cCellVisionGUI)
        trainCellVisionStageTwo(cCellVisionGUI)
        
        setCellVisionType(cCellVisionGUI)
        setPixelSize(cCellVisionGUI)
        setMinRadius(cCellVisionGUI)
        setMaxRadius(cCellVisionGUI)
        setNegTrainingNum(cCellVisionGUI)
        saveCellVision(cCellVisionGUI)
    end
end