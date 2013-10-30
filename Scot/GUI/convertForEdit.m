function handles = convertForEdit (handles)
    % converForEdit --- redefines the GUI for editing of segmentation results
    %
    % Synopsis: 	segmentOne (source, eventdata, handles)
    %
    % Input:	handles = structure, contains all GUI and timelapse information
    %
    % Output: 	handles = structure, contains all GUI and timelapse information
    
    % Notes: 	To be run after segmentation or loading a segmented
    %           timelapse.

    handles.mode='Edit';
    set(handles.panels.data,'Visible','On');
    set(handles.panels.requiredimages,'Visible','On');
    set(handles.panels.cellResult,'Visible','On');
    set(handles.cellnumBox,'Enable','On');
    set(handles.timepoint,'Enable','On');
    set(handles.cellnumBox,'Enable','On');
    set(handles.save,'Enable','On');
    set(handles.extractdata,'Enable','On');
    set(handles.runcomplete,'Enable','On');
    set(handles.deletethis,'Enable','On');
    set(handles.deleteall,'Enable','On');


    
    if ~isempty(handles.timelapse.Data)
        dataFields=fields(handles.timelapse.Data);
        handles.currentDataField=dataFields{1};
        handles=plotSegmented(handles);
        set(handles.exportdata,'Enable','On');
        set(handles.exportjpeg,'Enable','On');
    end
    handles=defineCallbacks(handles);
end