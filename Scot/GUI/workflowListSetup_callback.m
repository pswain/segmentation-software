function [handles]=workflowListSetup_callback(source, eventdata, handles)
    % workflowListSetup_callback ---  resets current method, level, parameter input controls and help information
    %
    % Synopsis:        handles = workflowListSetup_callback (handles)
    %
    % Input:           handles = structure, holds all gui information
    % 
    % Output:          handles = structure, holds all gui information
    
    % Notes:    Runs when user clicks in the workflow list. This callback
    %           is only used when setting up new timelapse segmentations. 
    %           For editing existing segmentations the alternative function
    %           workflowList_callback is used, which initializes level
    %           objects and displays images for the new level.
    %           
    handles=guidata(handles.gui);
    showMessage(handles,'');
    %First reset the current object if necessary
    handles.Level=get(source,'Value');
    %Set the new method
    handles.currentMethod=getMethod(handles);
    %Reset the current object if necessary/possible - will only be possible
    %if the current timepoint has been segmented
    if size(handles.levelObjects,2)>=handles.Level
    if ~isempty(handles.levelObjects(handles.Level).objects)
        handles.currentObj=handles.levelObjects(handles.Level).objects;
        handles=initializeCurrentObj(handles);
    end
    end
    
    
    %Update the rest of the GUI
    handles=setParameters(handles);
    
    %Check if it is necessary to show any result images - this may be the case if the run
    %single timepoint button has been pressed.
    if ~isempty(handles.timelapse.TrackingData)%This just to avoid an error on the next line if no cells have been segmented
    if size(handles.timelapse.TrackingData,2)>=handles.timelapse.CurrentFrame
    if ~isempty(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber))
        if size(handles.levelObjects,2)>=handles.Level
            handles.currentObj=handles.levelObjects(handles.Level).objects;
            %The current cell has been segmented. Check if the selected method was used on this cell
            methodList=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj;
            if handles.methodObjects(handles.Level).objects.ObjectNumber==methodList(handles.tdIndex(handles.Level))
                %The selected method was used in segmentation - display
                %relevant images
                handles=initializeCurrentObj(handles);
                handles=displayImages(handles);      
                handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
            else
                showMessage(handles, 'This method was not used in segmentation - result images are not relevant unless you segment again.');
                %Clear all displayed images
                %Clear the intermediate image and result of current method axes
                for n=1:size(handles.reqdImageAxes,2)
                    cla(handles.reqdImageAxes(n));
                    t=get(handles.reqdImageAxes(n),'Title');
                    delete(t);
                end
                cla(handles.panels.thisMethodResult);
            end
        end
    end
    end
    end
    handles=displayImages(handles);
    guidata(source, handles);    
end