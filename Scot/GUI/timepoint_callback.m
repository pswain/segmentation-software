function timepoint_callback(source, eventdata, handles)
    handles=guidata(handles.gui);
    cellnumber=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).cellnumber;
    timepoint=str2double(get(source,'String'));
    trackingnumbers=handles.timelapse.gettrackingnumbers(cellnumber);
    handles.timelapse.CurrentFrame=timepoint;
    handles.trackingnumber=trackingnumbers(handles.timelapse.CurrentFrame);
    if handles.trackingnumber>0
        handles.currentMethod=getMethod(handles, handles.trackingnumber);
        handles.historySize=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(1).methodobj,2);
        handles=setUpWorkflow(handles);
        handles.savedObj=handles.levelObjects(handles.Level).objects;
        handles.currentObj=handles.savedObj.copy;%the saved version of the current object
        handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object

    else%the cellnumber is not segmented at this timepoint
    end
    %Display the intermediate and result images
    handles=displayImages(handles);    
    guidata(handles.gui, handles);
    
end