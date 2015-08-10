function [handles]=accept_callback(source, eventdata, handles)
    % accept_callback --- records changes to the timelapse data in the saved version
    %
    % Synopsis:  [handles]=accept_callback(source, eventdata, handles)
    %                        
    % Input:     source = handle to the uicontrol that activates this callback
    %            eventdata =  structure carrying details of any events
    %            handles = structure carrying all gui and timelapse data
    %
    % Output:    handles = structure carrying all gui and timelapse data
    
    % Notes:     The returned data in handles is stored and accessed via
    %            guidata. This callback records any changes that have been
    %            made to handles.timelapse in the stored version,
    %            handles.savedtimelapse. It does not save to disk.  
        
    handles=guidata(handles.gui);%get the stored handles structure from the gui
    showMessage(handles,'Accepting changes...');%clear any messages
    %Replace the saved timelapse
    handles.savedtimelapse=handles.timelapse.copy;%Makes a deep copy, replacing the saved version.
    %Remove the accept and reject buttons
    set(handles.accept, 'Visible', 'Off');
    set(handles.reject, 'Visible', 'Off');
    showMessage(handles, 'Changes to timelapse data have been stored');
    %Display the intermediate and result images
    handles=displayImages(handles);
    guidata(source, handles);%save changes to the stored handles structure in the gui
end