function timelapseObj =  newSegmentation(varargin)
    % newSegmentation ---  Runs a GUI to to set up and run an initial timelapse segmentation
    %
    % Synopsis:        timelapse=Timelapse1(moviedir, interval, identifier)
    %                  timelapseObj=newSegmentation (moviedir, interval);
    %                  timelapseObj=newSegmentation (moviedir);
    %                  timelapseObj=newSegmentation;
    %
    % Input:           moviedir=string, the full path to a folder containing images from a timelapse experiment
    %                  interval = double, the time interval between timepoints in minutes
    %                  identifier = string, present in one file per timepoint, to be used as the main segmentation target

    % Output:          timelapseObj = an object of class Timelapse1.
    
    % Notes:           
    
    
    %Add the path to the segmentation classes
    thispath=mfilename('fullpath');
    k=strfind(thispath,'/');
    thispath=thispath(1:k(end-1));
    addpath(thispath);
    %First create the timelapse object - and add input information
    timelapseObj = Timelapse1(varargin{:});    
    %Set up the GUI
    handles=makeGUI(timelapseObj);
    %Set the mode - either 'Edit' or 'SetUp' - some callbacks behave
    %differently depending on the mode
    handles.mode='SetUp';
    %Modify the GUI for setting up new segmentations
    handles=newSegGUI(handles);
    %Initialize handles variables
    handles.Level=1;
    handles.timelapse=timelapseObj;
    handles.currentObj=timelapseObj;
    handles.currentMethod=timelapseObj.RunMethod;
    %Load main target images for display
    handles=loadRawImages(handles, handles.timelapse,'main');
    handles.rawDisplay=timelapseObj.ImageFileList(handles.timelapse.Main).identifier;%The set of images to be displayed initialy
    %This is a placeholder - should make displayImages able to cope with
    %absence of a defined region - ie no segmented cells
    handles.region=[1 1 30 30];

    
    handles=displayImages(handles);
    %Initialize the image selection list
    set(handles.tpresultaxes.channelselect,'String',{handles.rawDisplay;'Add channel'});
    %Set up the workflow
    handles=setUpNewWorkflow(handles);
    
    %Need to re-allocate the current method - any changes applied during
    %setting up the workflow need to be included - eg in
    %currentMethod.Classes.objectnumbers
    handles.currentMethod=handles.timelapse.RunMethod;
    handles=setParameters(handles);
    handles.trackingnumber=1;
    handles.cellnumber=0;
    handles.currentDataField=0;
    handles.trackdata=[];
    
    %Record the handles structure in the guidata
    guidata(handles.gui,handles);
    figure(gcf);  
end