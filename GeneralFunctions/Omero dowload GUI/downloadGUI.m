function  [folder omeroDs]=downloadGUI(singleDs, singlePos, server,user)
    %GUI function for downloading data from the Omero database. 'single' is a logical input.
    %If 'singleDs' is true - only one dataaset will be downloaded - to the folder specified by
    %the output variable 'folder', which is a string.
    %
    %If singlePos is true then only a single position will be downloaded
    
    %The other output variable is the dataset Id or Ids of the datasets
    %that have been downloaded
    disp('Running Omero download GUI...');
    %First define default input values
    if nargin<4
        user='upload';
    end
    if nargin<3
        server='skye.bio.ed.ac.uk';
    end
    handles.singleDs=false;
    handles.singlePos=false;
    if nargin>0
       handles.singleDs=singleDs;
       if nargin>1
          handles.singlePos=singlePos; 
       end
    end
    %Create an OmeroDatabase object    
    obj=OmeroDatabase(user, server);
    handles.obj=obj;

    %Create the figure
    handles.downloadDialog=figure('Units','Normalized','Position',[0.2815 0.3444 0.5756 0.5263],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Omero database download');
    %set(handles.downloadDialog('WindowStyle','Modal'); %Uncomment this when finished writing this function
    
    %Define data structures for display - add an 'All' option to allow
    %reselection of all datasets in a certain category
    handles.projNames=['All' obj.getProjectNames];
    dateArray=obj.getDates;
    handles.dateArray=['All' dateArray(:,1)'];
    handles.tagNames=['All' obj.getTagNames(false)];
    handles.userNames=['All' obj.getUsers];
    
    %Create the drop down selection lists
    handles.projList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.05 .7 .4 .2],'Style','popupmenu','String',handles.projNames,'Callback',@changeProject,'TooltipString','Choose a project to see the list of datasets that you can download');
    %handles.dsIdList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.05 .75 .2 .1],'Style','edit','String','','Callback',@enterId,'TooltipString','Enter the ID of the dataset you want to download');  
    handles.tagList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.55 .7 .4 .2],'Style','popupmenu','String',handles.tagNames,'Callback',@changeTag,'TooltipString','Choose a tag name to see the list of datasets with this tag');
    handles.dateList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.55 .65 .4 .2],'Style','popupmenu','String',handles.dateArray,'Callback',@changeTag,'TooltipString','Choose a date to see only datasets captured on this day');

    
    handles.downloadButton=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.55 .05 .4 .1],'Style','pushbutton','String','Download','Callback',@runDownload,'TooltipString','Click to download selected datasets');
    handles.dsTable=uitable('Parent',handles.downloadDialog,'Units','Normalized','Position',[.05 .2 .9 .6],'ColumnWidth',{60,200,200,300},'ColumnName',{'ID','Project','Name','Tags'},'CellSelectionCallback',@cellSelected, 'TooltipString', 'Select one or more dataset to download');
    handles.projText=uicontrol(handles.downloadDialog,'BackgroundColor',[0.8 0.8 0.8],'Units','Normalized','Position',[.05 .9 .4 .05],'Style','Text','String','Select a Project');
    handles.tagText=uicontrol(handles.downloadDialog,'BackgroundColor',[0.8 0.8 0.8],'Units','Normalized','Position',[.55 .9 .4 .05],'Style','Text','String','Select a Tag');
    
    
    
    %Get the info from the database
    data=obj.loadDbData;
    set(handles.dsTable,'data',data);
    handles.data=data;
    handles.subset=true(1,length(data));%This indicates which datasets to display (in this case all of them)
    guidata(handles.downloadDialog,handles);
    % Pause until resume function
    uiwait(handles.downloadDialog);
    handles=guidata(handles.downloadDialog);
    folder=handles.folder;
    omeroDs=handles.omeroDs;
    delete(handles.downloadDialog);
end

% function closefunction(hObject,eventdata) 
%         % This assigns the output variable 'folder'
%         folder=handles.folder;
%         % Close figure
%         delete(handles.downloadDialog);
% end