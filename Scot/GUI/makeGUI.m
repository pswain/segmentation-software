function handles=makeGUI(timelapseObj)
% makeGUI --- creates a graphical user interface for timelapse segmentation, editing and data extraction
%
% Synopsis:  handles = makeGUI (timelapseO)
%                        
% Input:     timelapseObj = an object of a Timelapse class
%
% Output:    obj = an object of a Timelapse class
%            
% Notes:     The handles to gui components are stored in the 'handles'
%            structure, along with the timelapse object and other timelapse
%            and gui information. Any functions or callbacks that do not
%            return the handles structure should save it in the guidata of
%            the main figure - ie guidata(handles.gui, handles). Callbacks
%            can then retrieve the latest version of handles with:
%            handles=guidata(handles.gui); The callbacks for the uicontrols
%            defined here are defined in the seperate function,
%            defineCallbacks.


handles=struct;
%Make GUI figure and panels
handles.gui=figure('Visible','off','Position',[10,10,1650,2850],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Single Cells Over Time - Timelapse segmentation, tracking and data extraction');
handles.panels.general = uipanel('Parent',handles.gui,'Title',timelapseObj.Name,'Units', 'normalized','Position',[0 .8125 .3333 .1875]);%[left bottom width height]
handles.panels.currentmethod = uipanel('Parent',handles.gui,'Title','Current Method','Units', 'normalized','Position',[0 .4750 .3333 .3375]);
handles.panels.data=uipanel('Parent',handles.gui,'Title','Data','Units', 'normalized','Position',[0 0 1 .25]);
handles.panels.requiredimages = uipanel('Parent',handles.gui,'Title','Intermediate images','Units', 'normalized','Position',[0.667 .25 .3333 .4334]);
handles.panels.workflow = uipanel('Parent',handles.gui,'Title','Segmentation Workflow','Units', 'normalized','Position',[0 .25 .3333 .225]);
handles.panels.info=uipanel('Parent',handles.gui,'Title','Info','Units', 'normalized','Position',[0.66667 .9 .3333 .1],'Title','Information');
handles.panels.inputoutput=uipanel('Parent',handles.gui,'Units', 'normalized','Title','Input/Output','Position',[0.7781 .7918 .2222 .1084]);
%Panels to show results at the timepoint, cell and region levels
handles.panels.tpResult = uipanel('Parent',handles.gui,'Units', 'normalized','Title','Timepoint','Position',[0.3333 0.25 .1665 .75]);
handles.panels.thisMethodResult = uipanel('Parent',handles.gui,'Units', 'normalized','Title','Result of Current Method','Position',[0.667 .6834 .1111 .2167]);
handles.panels.cellResult = uipanel('Parent',handles.gui,'Units', 'normalized','Title','Cell','Position',[0.4998 0.25 .1665 .75]);
%Edit panel
handles.panels.edit = uipanel('Parent',handles.gui,'Units', 'normalized','Title','Edit','Position',[0.7781 .6834 .2222 .1084]);


%Set up the Timelapse information panel
handles.directory=uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .75 .95 .25], 'String',['Experiment folder: ' timelapseObj.Moviedir],'HorizontalAlignment', 'Left');
handles.name=uicontrol('Parent',handles.panels.general,'Style', 'edit','Units', 'normalized','Position', [.015 .55 .2 .2], 'String',timelapseObj.Name,'HorizontalAlignment', 'Left');
uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .35 .2 .2], 'String',['Timepoints:' num2str(timelapseObj.TimePoints)],'HorizontalAlignment', 'Left');
uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .20 .2 .2], 'String',['Interval:' num2str(timelapseObj.Interval) 'min'],'HorizontalAlignment', 'Left');
uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position',[.25 .52 .3 .2], 'String','Cell number:','HorizontalAlignment', 'Left', 'FontSize', 16);
handles.cellnumBox=uicontrol('Parent',handles.panels.general,'Style', 'edit','Units', 'normalized','Position',[.5 .52 .1 .2], 'String','1','HorizontalAlignment', 'Left', 'FontSize', 16);
uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position',[.25 .25 .3 .2], 'String','Timepoint:','HorizontalAlignment', 'Left', 'FontSize', 16);
handles.timepoint=uicontrol('Parent',handles.panels.general,'Style', 'edit','Units', 'normalized','Position',[.5 .27 .1 .2], 'String',num2str(timelapseObj.CurrentFrame),'HorizontalAlignment', 'Left', 'FontSize', 16);
%Set up the info panel
handles.infobox=uicontrol('Parent',handles.panels.info,'Style', 'text','Units', 'normalized','Position',[0.015 .015 0.985 .985],'HorizontalAlignment', 'Left');
[handles.progressBarJ handles.progressBarM]=javacomponent(javax.swing.JProgressBar);
handles.progressBarJ.setStringPainted(true);
set(handles.progressBarM,'Parent',handles.panels.info);
set(handles.progressBarM,'Parent',handles.panels.info,'Units','Normalized','Position',[0.005 0.005 .995 .2])
%Make visible - to show progress with rest of gui setup
figure(gcf);

%Set up axes, menu and sliders to display the result and target images
handles.tpresultaxes.target=axes('Parent',handles.panels.tpResult,'Position',[0 0.6234 1 .3117],'Visible','Off');
handles.tpresultaxes.binary=axes('Parent',handles.panels.tpResult,'Position',[0 0.3117 1 .3117], 'Visible', 'Off');
handles.tpresultaxes.merged=axes('Parent',handles.panels.tpResult,'Position',[0 0 1 .3117], 'Visible', 'Off');
handles.tpresultaxes.slider=uicontrol('Style','slider',...
                'Parent',handles.panels.tpResult,...
                'Min',1,...
                'Max',timelapseObj.TimePoints,...
                'Value', 1,...
                'Units','normalized',...
                'Position',[0.005 .935 .995 .02],...
                'SliderStep',[1/timelapseObj.TimePoints 1/timelapseObj.TimePoints]);
handles.tpresultaxes.channelselect=uicontrol('Parent',handles.panels.tpResult,'Style', 'popupmenu','Units', 'normalized','Position', [.015 .94 .8 .05], 'String','Add channel','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','On','Tooltipstring','Select and add channels for browsing the raw data');

handles.cellresultaxes.target=axes('Parent',handles.panels.cellResult,'Position',[0 0.6334 1 .3117], 'Visible', 'Off');
handles.cellresultaxes.binary=axes('Parent',handles.panels.cellResult,'Position',[0 0.3167 1 .3117], 'Visible', 'Off');
handles.cellresultaxes.merged=axes('Parent',handles.panels.cellResult,'Position',[0 0 1 .3117], 'Visible', 'Off');
handles.cellresultaxes.zoomslider=uicontrol('Style','slider',...
                'Parent',handles.panels.cellResult,...
                'Min',0.01,...
                'Max',1,...
                'Value', .01,...
                'Units','normalized',...
                'Position',[0.005 .935 .995 .02],...
                'SliderStep',[.01 .01]);

            
            
handles.intResult=axes('Parent', handles.panels.thisMethodResult,'Position',[0 0 1 1],'Visible','Off');




%Set up axes to display the required images for the current method. 6 are created.
handles.reqdImageAxes(1)=axes('Parent',handles.panels.requiredimages,'Position',[.05 .495 .33 .495], 'Visible', 'Off');%bl
handles.reqdImageAxes(2)=axes('Parent',handles.panels.requiredimages,'Position',[.05 .05 .33 .495], 'Visible', 'Off');%tr
handles.reqdImageAxes(3)=axes('Parent',handles.panels.requiredimages,'Position',[.05+.33 .495 .33 .495], 'Visible', 'Off');%ml
handles.reqdImageAxes(4)=axes('Parent',handles.panels.requiredimages,'Position',[.05+.33 .05 .33 .495], 'Visible', 'Off');%mr
handles.reqdImageAxes(5)=axes('Parent',handles.panels.requiredimages,'Position',[.05+.66 .495 .33 .495], 'Visible', 'Off');%?
handles.reqdImageAxes(6)=axes('Parent',handles.panels.requiredimages,'Position',[.05+.66 .05 .33 .495], 'Visible', 'Off');%br

%Set up the Current method panel
handles.restoreDefaults=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.5 .94 .13 .05],'String','Defaults','Enable','off');
handles.restoreInitial=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.65 .94 .13 .05],'String','Initial','Enable','off');
handles.shuffle=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.8 .94 .10 .05],'String','More','Enable','Off','HorizontalAlignment', 'Left');
handles.accept=uicontrol('Parent',handles.panels.general,'Style', 'pushbutton','Units', 'normalized','Position',[.65 .50 .25 .25], 'String','Accept changes','HorizontalAlignment', 'Left','ForegroundColor', [.2 .5 .2],'Visible','Off');
handles.reject=uicontrol('Parent',handles.panels.general,'Style', 'pushbutton','Units', 'normalized','Position',[.65 .25 .25 .25], 'String','Reject changes','HorizontalAlignment', 'Left','ForegroundColor', [.7 0.2 0.2],'Visible','Off');

%There are five 'run' buttons:
%handles.runcomplete - to run whole timelapse segmentation - change name to handles.segmenttimelapse
%handles.run - to run current method - change name to handles.runcurrent
%handles.runschedule - starts scheduled tasks running
%handles.extractdata - sets up extract data method
%handles.segmentsingle - runs segmentation on a single timepoint
handles.run=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position', [.34 .015 .3 .12],'String','Run method','HorizontalAlignment', 'Left', 'TooltipString','Run this method to see immediate result image. This will not overwrite saved data.','BackgroundColor', [.7 1 .7],'enable','off');
handles.segmentsingle=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position', [.665 .015 .3 .12],'String','Segment timepoint','HorizontalAlignment', 'Left', 'TooltipString','Segment a single timepoint using the currently-defined methods.','BackgroundColor', [.7 1 .7]);
handles.runNewSeg=uicontrol('Parent', handles.panels.general, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.65 .50 .24 .22],'String','Segment timelapse','HorizontalAlignment', 'Left', 'TooltipString','Run to completion of timelapse segmentation and tracking, replacing the current method in the workflow. This will not overwrite saved data','BackgroundColor', [.7 1 .7]);
handles.schedule=uicontrol('Parent', handles.panels.general, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.65 .26 .24 .22],'String','Schedule','HorizontalAlignment', 'Left', 'TooltipString','Schedule more than one timelapse segmentation and data extraction task. Click here to define folders having data to segment and data extraction methods.','BackgroundColor', [1 .6 0.4]);
handles.runschedule=uicontrol('Parent', handles.panels.general, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.65 .02 .24 .22],'String','Run Schedule','HorizontalAlignment', 'Left', 'TooltipString','Run scheduled segmentation and data extraction tasks.','BackgroundColor', [.7 1 .7],'Enable','Off');
handles.runcomplete=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.015 .015 .3 .12],'String','Run to completion','HorizontalAlignment', 'Left', 'TooltipString','Run segmentation starting with the currently-selected method and proceeding to end of workflow','BackgroundColor', [.7 1 .7], 'Enable','Off');
handles.extractdata=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.50 .76 .17 .15],'String','Extract data','HorizontalAlignment', 'Left', 'TooltipString','Click to extract data from a segmented timelapse.','BackgroundColor', [0.6 0.6 1],'Enable','Off');
handles.methodName=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .88 .3 .1], 'String','Method Name','HorizontalAlignment', 'Left','FontWeight','Bold', 'FontSize',12);
handles.initialize=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.30 .76 .17 .15],'String','Show intermediates','HorizontalAlignment', 'Left', 'TooltipString','Click to show intermediate images for the current selection.','Enable','On');


%Set up controls to set the method parameters - 9 are created
uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .77 .2 .06], 'String','Parameters','HorizontalAlignment', 'Left','FontSize',14);
handles.parameterName(1)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .68 .3 .06], 'String','Parameter1','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(1)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .55 .3 .12], 'String','Parameter1','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(1)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.015 .55 .3 .12], 'String','Parameter1','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(1)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.2 .55 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(2)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .47 .3 .06], 'String','Parameter2','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(2)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .35 .3 .12], 'String','Parameter2','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(2)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.015 .35 .3 .12], 'String','Parameter2','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(2)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.2 .35 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(3)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .26 .3 .06], 'String','Parameter3','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(3)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .15 .3 .12], 'String','Parameter3','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(3)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.015 .15 .3 .12], 'String','Parameter3','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(3)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.2 .15 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(4)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .68 .2 .06], 'String','Parameter4','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(4)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.34 .55 .3 .12], 'String','Parameter4','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(4)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.34 .55 .3 .12], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(4)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [0.525 .55 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(5)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .47 .3 .06], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(5)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.34 .35 .3 .12], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(5)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.34 .35 .3 .12], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(5)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [0.525 .35 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(6)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .26 .3 .06], 'String','Parameter6','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(6)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.34 .15 .3 .12], 'String','Parameter6','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(6)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [0.34 .15 .3 .12], 'String','Parameter6','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(6)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [0.525 .15 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(7)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .68 .2 .06], 'String','Parameter7','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(7)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .55 .3 .12], 'String','Parameter7','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(7)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [0.665 .55 .3 .12], 'String','Parameter7','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(7)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.85 .55 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(8)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .47 .3 .06], 'String','Parameter8','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(8)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .35 .3 .12], 'String','Parameter8','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(8)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [0.665 .35 .3 .12], 'String','Parameter8','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(8)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.85 .35 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

handles.parameterName(9)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .26 .3 .06], 'String','Parameter9','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
handles.parameterBox(9)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .15 .3 .12], 'String','Parameter9','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');
handles.parameterDrop(9)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [0.665 .15 .3 .12], 'String','Parameter9','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off');
handles.parameterCall(9)=uicontrol('Parent',handles.panels.currentmethod,'Style','Pushbutton','Units', 'normalized','Position', [.85 .15 .12 .12], 'String','Change','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Visible','Off','ToolTipString','Click here to change this parameter');

%Make a control to select the data extraction method - to be visible after
%the extractdata button is clicked
extractMethods=MethodsSuperClass.listMethodClasses('extractdata');%Returns the list of extract data methods
handles.extractDataMethod=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.7 .76 .27 .15], 'String',extractMethods,'HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','off','Value',1);


%Set up the workflow panel
handles.workflowList=uicontrol('Parent',handles.panels.workflow,'Style','listbox','Units', 'normalized', 'Position',[.015 0.05 .2 .9]);
handles.description=uicontrol('Parent',handles.panels.workflow,'Style','edit','String', 'Method description','Max',5,'Units','normalized', 'Enable','on','BackgroundColor',[0.6 0.6 .7],'Position',[.295 0.05 .7 .9],'HorizontalAlignment','left');
handles.proceed=uicontrol('Parent',handles.panels.workflow,'Style','pushbutton','Units', 'normalized','Position',[.217 0.75 .076 .1],'String','Down','HorizontalAlignment', 'Left', 'TooltipString','Select next item on workflow list');

%Set up the edit panel
handles.deletethis=uicontrol('Parent',handles.panels.edit,'Style','pushbutton','Units', 'normalized','Position',[.015 0.75 .35 .2],'String','Delete','HorizontalAlignment', 'Left', 'TooltipString','Delete this cell at the current timepoint only.','Enable','Off');
handles.deleteall=uicontrol('Parent',handles.panels.edit,'Style','pushbutton','Units', 'normalized','Position',[.015 0.5 .35 .2],'String','Remove from dataset','HorizontalAlignment', 'Left', 'TooltipString','Delete this cell at all timepoints.','Enable','Off');

%Set up the input/output panel
handles.load=uicontrol('Parent',handles.panels.inputoutput,'Style','pushbutton','Units', 'normalized','Position',[.015 0.75 .3 .2],'String','Load timelapse','HorizontalAlignment', 'Left', 'TooltipString','Click here to load a saved timelapse dataset');
handles.save=uicontrol('Parent',handles.panels.inputoutput,'Style','pushbutton','Units', 'normalized','Position',[.015 0.52 .3 .2],'String','Save timelapse','HorizontalAlignment', 'Left', 'TooltipString','Click here to save this timelapse');
handles.exportdata=uicontrol('Parent',handles.panels.inputoutput,'Style','pushbutton','Units', 'normalized','Position',[.335 0.75 .3 .2],'String','Export data','HorizontalAlignment', 'Left', 'TooltipString','Click here to export extracted data to a file readable by Excel', 'Enable','Off');
handles.exportjpeg=uicontrol('Parent',handles.panels.inputoutput,'Style','pushbutton','Units', 'normalized','Position',[.335 0.52 .3 .2],'String','Export graph','HorizontalAlignment', 'Left', 'TooltipString','Click here to export the currently-displayed graph in JPEG format', 'Enable','Off');

%Set up the plot panel
handles.plot=axes('Parent',handles.panels.data,'Units','normalized','Position',[0 0 1 1],'Visible','Off');
handles.selectGraph=uicontrol('Parent', handles.panels.data,'Style', 'Popup','Units', 'normalized','Position',[0.005 .80 .15 .15],'String', 'To be defined','Visible', 'Off','TooltipString','Select alternative data set to display');

end