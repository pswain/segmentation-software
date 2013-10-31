function [handles]=reject_callback(source, eventdata, handles)
    % reject_callback --- restores saved version of the timelapse data
    %
    % Synopsis:  [handles]=accept_callback(source, eventdata, handles)
    %                        
    % Input:     source = handle to the uicontrol that activates this callback
    %            eventdata =  structure carrying details of any events
    %            handles = structure carrying all gui and timelapse data
    %
    % Output:    handles = structure carrying all gui and timelapse data
    
    % Notes:     The returned data in handles is stored and accessed via
    %            guidata. This callback reverts handles.timelapse to the
    %            stored version, handles.savedtimelapse and updates the gui
    %            display.
    showMessage(handles, 'Discarding changes...');
    handles=guidata(handles.gui);%get the stored handles structure from the gui
    %Record the current timepoint - needed for making a new currentObj
    timepoint=handles.timelapse.CurrentFrame;
    handles.timelapse=handles.savedtimelapse.copy;%Makes a deep copy, replacing the existing handles.timelapse
    handles.timelapse.CurrentFrame=timepoint;
    %Remove the accept and reject buttons
    set(handles.accept, 'Visible', 'Off');
    set(handles.reject, 'Visible', 'Off');
    %Reset the current object and method
    %First set up the workflow
    handles=setUpWorkflow(handles);
    handles.currentMethod=getMethod(handles);
    handles.currentObj=handles.savedObj.copy;
    handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
    handles=initializeCurrentObj(handles);
    %Populate the drop down lists in the currentMethod panel
    handles=populateMethod(handles);
    handles=populatePackage(handles);
    %Display the intermediate and result images
    handles=displayImages(handles);
    %Update the data display
    %....
    showMessage(handles, 'Changes to timelapse data have been discarded');
    guidata(source, handles);%save changes to the stored handles structure in the gui
end