function handles = beginEdit (handles)
    % beginEdit --- initiates timelapse editing/data extraction    
    %
    % Synopsis:  handles = beginEdit (handles)
    %
    % Input:     handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     To be called after segmenation and tracking of a new
    %            timelapse dataset or loading of a saved one. Initializes
    %            the GUI and handles variables for editing and data
    %            extraction. The field handles.timelapse must be populated
    %            with a tracked timelapse object before this function is
    %            called.
    
   
    %Initialize handles variables
    handles.currentDataField=[];
    handles.mode='Edit';
    %Identify the first segmented cell - the cell with the lowest
    %trackingnumber in the first timepoint at which any cells are
    %segmented. Also define handles.trackingnumber, handles.cellnumber and
    %handles.region, relating to this cell
    t=1;
    handles.timelapse.CurrentFrame=[];
    while isempty(handles.timelapse.CurrentFrame)
        if ~isempty(handles.timelapse.TrackingData(t).cells)%could catch an error here - will give an index out of bounds if there are no segmented cells
            handles.timelapse.CurrentFrame=t;
        t=t+1;
        end
    end
    handles.trackingnumber=min([handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells.trackingnumber]);
    handles.cellnumber=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).cellnumber;
    handles.timelapse.CurrentCell=handles.cellnumber;
    %Convert the GUI for editing segmentations
    handles=convertForEdit(handles);
    
    handles.region=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(1).region;   
    %Create the result images for display
    handles.timelapse=handles.timelapse.makeDisplayResult;
    %Create the saved timelapse object
    handles.savedtimelapse=handles.timelapse.copy;%Makes a deep copy.
    handles.Level=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj,2);
    %Set up the workflow - based on information stored in
    %handles.timelapse.TrackingData
    handles=setUpWorkflow(handles);
    handles=loadRawImages(handles, handles.timelapse, 'main');
    handles.Level=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj,2);

    %Initialize other handles fields
    handles.currentMethod=handles.methodObjects(handles.Level).objects;
    handles.currentObj=handles.levelObjects(handles.Level).objects;
    handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
    handles.savedObj=handles.currentObj.copy;
    handles=initializeCurrentObj(handles);
    
    %Display the intermediate and result images
    handles=displayImages(handles);
    guidata(handles.gui,handles);
    %Tell the user what to do
    showMessage(handles,'Edit and extract data from timelapse.');
end