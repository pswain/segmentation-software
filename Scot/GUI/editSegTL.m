%the handles structure

%Has handles for all of the uicontrols - but also used to pass around other
%information

% .currentObj - the current level object
% .timelapse - the saved timelapse object
% .tempTimelapse - a temporary timelapse object to be accepted or rejected - this cannot yet be implemented - need to write a copy class for that
% .trackingnumber - of the current cell
% .Level - integer - an index to the history and the handles.workflow* entries - gives the level of the current method object
% .currentMethod - the current method object
% .workflowNames - class names of the method and level objects in the workflow
% .workflowLevel - class names of the level objects acted upon by the method objects in the history
% .workflowResultImageNames - names of the level object properties to which the output of the run methods write the results
% .workflowLevelObjects - the level objects (or handles to them)
function editSegTL (timelapseObj, handles)
    % editSegTL ---  Runs a GUI to edit and extract data from an input timelapse segmentation
    %
    % Synopsis:        timelapseObj=editSegTL (timelapseObj);
    %                  timelapseObj=editSegTL (timelapseObj, handles);
    %
    % Input:           timelapseObj = an object of a timelapse class, segmented and tracked
    %                  handles = structure, carrying all GUI information

    % Output:          
    
    % Notes:           This function accepts completed timelapse
    %                  segmentations that have been run either from the
    %                  Matlab command line or through the GUI. In the
    %                  latter case the handles structure is input carrying
    %                  GUI information so not all of the GUI controls and
    %                  variables need to be set up from scratch.

%Create or redefine the GUI space and panels
if nargin==1
    handles=makeGUI(timelapseObj);
    %Need to populate some of the workflow variables that won't have been
    %made with command line segmentation - do this later
else
    %Need to alter several GUI functions to allow segmentation editing.
    handles=convertForEdit(handles);

end
    
%Start Fiji (used for some image processing functions)
%First set up the classpath using the Miji script - need to find the
%directory in which the fiji application directory is located. It is two
%levels up from the current one.
thispath=mfilename('fullpath');
k=strfind(thispath,'/');
thispath=thispath(1:k(end-1));
addpath(thispath);
%split=strread(thispath,'%s', 'delimiter','/');
%twofromend=size(char(split(end)),2);
%thatpath=thispath(1:end-twofromend);
addpath([thispath 'Fiji.app/scripts']);
Miji;

%Identify the first segmented cell - the cell with trackingnumber 1 in the
%first timepoint at which any cells are segmented.
t=1;
timelapseObj.CurrentFrame=[];
while isempty(timelapseObj.CurrentFrame)
    if ~isempty(timelapseObj.TrackingData(t).cells)%could catch an error here - will give an index out of bounds if there are no segmented cells
        timelapseObj.CurrentFrame=t;
    t=t+1;
    end
end
%Create the saved and temporary timelapse objects
handles.savedtimelapse=timelapseObj;
handles.timelapse=timelapseObj.copy;%Makes a deep copy.
handles.trackingnumber=1;
handles.cellnumber=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(1).cellnumber;
handles.Level=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj,2);
%Set up the workflow
handles=setUpWorkflow(handles);
%Initialize other handles fields
handles.currentMethod=handles.methodObjects(handles.Level).objects;
handles.currentObj=handles.levelObjects(handles.Level).objects;
handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
handles.savedObj=handles.currentObj.copy;
handles=initializeCurrentObj(handles);
%Populate the drop down lists in the currentMethod panel
handles=populatePackage(handles);
handles=populateMethod(handles);
%Display the intermediate and result images
handles=displayImages(handles);
handles=defineCallbacks(handles);
%store the handles structure in guidata for use by callbacks
fig;
guidata(handles.gui,handles);
end