function  [folder omeroDs]=downloadGUI(singleDs, singlePos)
    %GUI function for downloading data from the Omero database. 'single' is a logical input.
    %If 'singleDs' is true - only one dataaset will be downloaded - to the folder specified by
    %the output variable 'folder', which is a string.
    %
    %If singlePos is true then only a single position will be downloaded
    
    %The other output variable is the dataset Id or Ids of the datasets
    %that have been downloaded
    disp('Running Omero download GUI...');
    handles.singleDs=false;
    handles.singlePos=false;
    if nargin>0
       handles.singleDs=singleDs;
       if nargin>1
          handles.singlePos=singlePos; 
       end
    end
    %Prepare the path
    addpath(genpath('/Volumes/AcquisitionData2/Swain Lab/OmeroCode'));
    %Load the latest version of the OmeroDatabase object - this has all the
    %recorded contents of the database - much more convenient than querying the
    %database itself
    SavePath='/Volumes/AcquisitionData2/Swain Lab/Ivan/software in progress/omeroinfo_donottouch/dbInfo.mat';%Path to the saved object representing the current state of the database
    if ~exist(SavePath)==2
        error('Omero code not found - make sure you are connected to the microscope computer (129.215.109.100)');
    end
    load(SavePath);

    %Prepare the path
    addpath(genpath('/Volumes/AcquisitionData2/Swain Lab/OmeroCode'));
    OmeroDatabase.preparePath;
    obj2=obj2.login;
    %Parse the important info into cell arrays
    handles.downloadDialog=figure('Units','Normalized','Position',[0.2815 0.3444 0.5756 0.5263],'MenuBar','None', 'NumberTitle', 'Off', 'Name', 'Omero database download');
    %set(handles.downloadDialog('WindowStyle','Modal'); %Uncomment this when finished
    %writing this function
    handles.obj=obj2;
    handles.projNames=obj2.getProjectNames;
    handles.projList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.05 .7 .4 .2],'Style','popupmenu','String',handles.projNames,'Callback',@changeProject,'TooltipString','Choose a project to see the list of datasets that you can download');
    %handles.dsIdList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.05 .75 .2 .1],'Style','edit','String','','Callback',@enterId,'TooltipString','Enter the ID of the dataset you want to download');
    handles.tagNames=obj2.getTagNames(true);
    handles.tagList=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.55 .7 .4 .2],'Style','popupmenu','String',handles.tagNames,'Callback',@changeTag,'TooltipString','Choose a tag name to see the list of datasets with this tag');
    handles.downloadButton=uicontrol(handles.downloadDialog,'Units','Normalized','Position',[.55 .05 .4 .1],'Style','pushbutton','String','Download','Callback',@runDownload,'TooltipString','Click to download selected datasets');
    handles.dsTable=uitable('Parent',handles.downloadDialog,'Units','Normalized','Position',[.05 .2 .9 .6],'ColumnWidth',{60,200,200,300},'ColumnName',{'ID','Project','Name','Tags'},'CellSelectionCallback',@cellSelected, 'TooltipString', 'Select one or more dataset to download');
    handles.projText=uicontrol(handles.downloadDialog,'BackgroundColor',[0.8 0.8 0.8],'Units','Normalized','Position',[.05 .9 .4 .05],'Style','Text','String','Select a Project');
    handles.tagText=uicontrol(handles.downloadDialog,'BackgroundColor',[0.8 0.8 0.8],'Units','Normalized','Position',[.55 .9 .4 .05],'Style','Text','String','Select a Tag');

    %Get the info from the database
    data=obj2.loadDbData;
    set(handles.dsTable,'data',data);
    handles.data=data;
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