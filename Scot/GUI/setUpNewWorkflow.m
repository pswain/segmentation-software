function handles = setUpNewWorkflow (handles)        
    % setUpNewWorkflow ---  defines the segmentation workflow for segmentations that have not yet been run and sets these in the relevant GUI controls
    %
    % Synopsis:        handles=setUpNewWorkflow(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    This function is only for use in setting up new
    % segmentations. For setting up a workflow during editing of
    % segmentation results use the alternative function setUpWorkflow.
    % This function defines the following components of the handles
    % structure based on the information in the Classes fields of method
    % objects, starting with the timelapse run method.
    %
    %   handles.historySize = the number of items in the workflow 
    %   handles.workflowNames = the names of each object in the workflow
    %   handles.workflowLevels = the type of level object ('OneCell', 'Region', 'Timepoint' or 'Timelapse') that each object either is or has worked on.
    %   handles.workflowResultImageNames = the name of the image or other field that each method has written its result to.
    %   handles.levelObjects = the handles to the level objects worked on at each stage of the workflow
    %   handles.workflowAlternatives = logical array recording if the methods in the workflow are alternatives, one of which will eventually be used if successful
    %   handles.methodObjects = method objects at each level in the workflow

    %Initialize the entries in the handles structure    
    handles.historySize=0;
    handles.workflowNames={};
    handles.workflowLevels={};
    handles.workflowResultImageNames={};
    handles.workflowAlternatives=0;
    handles.methodObjects=struct;
    %Call the follow workflow function, which keeps calling itself until
    %the workflow is complete
    handles=followWorkflow(handles, 'Level','Timelapse',0,0);
    handles.Level=1;
    %Intialize the levelObjects structure with the correct size
    handles.levelObjects=struct('objects',{});%This structure cannot be populated until the segmentation is run.
    handles.levelObjects(handles.historySize).objects=[];
    %Replace the RunMethod of the timelapse object - to incorporate any
    %changes that occured during setting up of the workflow
    handles.timelapse.RunMethod=handles.methodObjects(1).objects;
    %Update the GUI
    handles=highlightWorkflow(handles);
    set(handles.workflowList,'Value',handles.Level);
    
end


   
    
    
    
    
