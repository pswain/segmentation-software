function handles=makeNewSegGUI(timelapseObj)
    % makeNewSegGUI ---  Sets up the components of a GUI to set up new timelapse segmentations
    %
    % Synopsis:        handles = makeNewSegGUI;
    %
    % Input:           
    %
    % Output:          handles = structure, holds all the GUI information
    
    % Notes:           
    
    
    handles=struct;
    %Make GUI figure and panels
    handles.gui=figure('Visible','off','Units', 'Normalized','Position',[.2,.5,.5,.4],'MenuBar','None');
    %Create 2 panels
    handles.panels.general = uipanel('Parent',handles.gui,'Title',timelapseObj.Name,'Units', 'normalized','Position',[0 0.5 .5 .5]);%[left bottom width height]
    handles.panels.info = uipanel('Parent',handles.gui,'Title','Info','Units', 'normalized','Position',[0.5 0.5 .5 .5]);%[left bottom width height]
    handles.panels.currentmethod = uipanel('Parent',handles.gui,'Title','Current Method','Units', 'normalized','Position',[0 0 1 .5]);
    

    %Set up the Timelapse information panel
    handles.moviedir=uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .8 .95 .2], 'String',['Experiment folder:' timelapseObj.Moviedir],'HorizontalAlignment', 'Left');
    handles.name=uicontrol('Parent',handles.panels.general,'Style', 'edit','Units', 'normalized','Position', [.015 .60 .2 .2], 'String',timelapseObj.Name,'HorizontalAlignment', 'Left');
    uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .40 .2 .2], 'String',['Timepoints:' num2str(timelapseObj.TimePoints)],'HorizontalAlignment', 'Left');
    uicontrol('Parent',handles.panels.general,'Style', 'text','Units', 'normalized','Position', [.015 .25 .2 .2], 'String',['Interval:' num2str(timelapseObj.Interval) 'min'],'HorizontalAlignment', 'Left');
    %Set up the info panel
    handles.infobox=uicontrol('Parent',handles.panels.info,'Style', 'text','Units', 'normalized','Position',[0.015 .015 0.985 .985],'HorizontalAlignment', 'Left');



    %Set up the Current method panel
    uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .94 .2 .05], 'String','Package:','HorizontalAlignment', 'Left');
    handles.packageMenu=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.13 .94 .35 .05],'String','Package list not populated','Value', 1);
    uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position',[.015 .85 .1 .05], 'String','Method:','HorizontalAlignment', 'Left');
    handles.methodsMenu=uicontrol('Parent',handles.panels.currentmethod,'Style', 'popupmenu','Units', 'normalized','Position', [.13 .86 .35 .05],'String','Method list not populated','Value', 1);
    handles.restoreDefaults=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.5 .94 .13 .05],'String','Defaults');
    handles.restoreInitial=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.65 .94 .13 .05],'String','Initial');
    handles.shuffle=uicontrol('Parent',handles.panels.currentmethod,'Style', 'pushbutton','Units', 'normalized','Position', [.8 .94 .10 .05],'String','More','Enable','Off','HorizontalAlignment', 'Left');
    handles.run=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position', [.5 .79 .13 .12],'String','Run','HorizontalAlignment', 'Left', 'TooltipString','Run this method to see immediate result image. This will not overwrite saved data.');
    set(handles.run,'BackgroundColor', [.7 1 .7],'enable','off');
    handles.runcomplete=uicontrol('Parent', handles.panels.currentmethod, 'Style', 'Pushbutton', 'Units', 'normalized', 'Position',[.65 .79 .24 .12],'String','Run whole workflow','HorizontalAlignment', 'Left', 'TooltipString','Run to completion of timelapse segmentation and tracking, replacing the current method in the workflow. This will not overwrite saved data');
    set(handles.runcomplete,'BackgroundColor', [.7 1 .7]);




    %Set up controls to set the method parameters - 12 are created
    uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .77 .2 .06], 'String','Parameters','HorizontalAlignment', 'Left','FontSize',14);
    handles.parameterName(1)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .68 .3 .06], 'String','Parameter1','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(1)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .55 .3 .12], 'String','Parameter1','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(2)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .47 .3 .06], 'String','Parameter2','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(2)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .35 .3 .12], 'String','Parameter2','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(3)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.015 .26 .3 .06], 'String','Parameter3','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(3)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.015 .15 .3 .12], 'String','Parameter3','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(4)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .68 .2 .06], 'String','Parameter4','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(4)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.34 .55 .3 .12], 'String','Parameter4','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(5)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .47 .3 .06], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(5)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [.34 .35 .3 .12], 'String','Parameter5','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(6)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [.34 .26 .3 .06], 'String','Parameter6','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(6)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.34 .15 .3 .12], 'String','Parameter6','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(7)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .68 .2 .06], 'String','Parameter7','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(7)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .55 .3 .12], 'String','Parameter7','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(8)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .47 .3 .06], 'String','Parameter8','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(8)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .35 .3 .12], 'String','Parameter8','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')
    handles.parameterName(9)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'text','Units', 'normalized','Position', [0.665 .26 .3 .06], 'String','Parameter9','HorizontalAlignment', 'Left','FontSize',12,'Enable','Off');
    handles.parameterBox(9)=uicontrol('Parent',handles.panels.currentmethod,'Style', 'edit','Units', 'normalized','Position', [0.665 .15 .3 .12], 'String','Parameter9','HorizontalAlignment', 'Left','FontSize',12,'Max', 2, 'Min', 0,'Enable','Off');%'Visible','Off')

    %Set up the workflow panel
    handles.workflowList=uicontrol('Parent',handles.panels.workflow,'Style','listbox','Units', 'normalized', 'Position',[.015 0.05 .2 .9]);
    handles.description=uicontrol('Parent',handles.panels.workflow,'Style','edit','String', 'Method description','Max',5,'Units','normalized', 'Enable','on','BackgroundColor',[0.6 0.6 .7],'Position',[.215 0.05 .8 .9],'HorizontalAlignment','left');%Maybe this should be duplicated in the methods panel

    %Set up the plot panel
    handles.plot=axes('Parent',handles.panels.data,'Units','normalized','Position',[0 0 1 1],'Visible','Off');
    handles.selectPoint=uicontrol('Parent', handles.panels.data,'Style', 'Pushbutton','Units', 'normalized','Position',[0.005 .82 .05 .15],'String', 'Select point','Visible', 'Off');
end