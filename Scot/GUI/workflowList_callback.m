function [handles]=workflowList_callback(source, eventdata, handles)
    % workflow_callback ---  resets current method and level objects and updates GUI fields
    %
    % Synopsis:        handles = workflowList_callback (handles)
    %
    % Input:           handles = structure, holds all gui information
    % 
    % Output:          handles = structure, holds all gui information
    
    % Notes:    Runs when user clicks in the workflow list. This callback
    %           is used when editing segmentation results or setting up new
    %           segmentations. In the latter case this function does not
    %           initialize level objects or display images.
    %       
    handles=guidata(handles.gui);
    %Clear message display
    showMessage(handles,'');
    %First reset the current object if necessary
    handles.Level=get(source,'Value');
    %Reset the current object, based on the selected level in the workflow
    if strcmp(handles.mode,'Edit');
        handles.savedObj=handles.levelObjects(handles.Level).objects;
        handles.savedObj=handles.savedObj.initializeFields;
        handles.currentObj=handles.savedObj.copy;%the saved version of the current object
        handles.currentObj.Timelapse=handles.timelapse;%This is essential so that the temp timelapse gets altered when you run methods on the temporary object
        set(handles.initialize,'Enable','On');
        showMessage('Click initialize button to calculate and display intermediate images for the currently-selecte method');
    else%GUI is in 'Setup' mode - can only update the current object if the current timepoint has been segmented
        if size(handles.levelObjects,2)>=handles.Level
            if ~isempty(handles.levelObjects(handles.Level).objects)
                handles.currentObj=handles.levelObjects(handles.Level).objects;
                 set(handles.initialize,'Enable','On');
                 showMessage('Click initialize button to calculate and display intermediate images for the currently-selecte method');
            else
                set(handles.initialize,'Enable','Off');
            end
        end
    end
    %Set the new method
    handles.currentMethod=getMethod(handles);
    
    %Update other GUI options based on the type of method selected
    handles.currentMethod.Info=metaclass(handles.currentMethod);
    
    if ~strcmp(handles.currentMethod.Info.ContainingPackage.Name,'extractdata') && strcmp(handles.mode,'Edit')
       set(handles.extractdata,'Enable','on');
       set(handles.extractDataMethod,'Enable','off');
       set(handles.extractdata,'String','Extract data','TooltipString','Click to extract data from a segmented timelapse.','BackgroundColor', [0.6 0.6 1]);
    end   
    
    %Update the method panel
    handles=setParameters(handles);
    
    %Determine correct state of the Run button
    
    %Display the intermediate and result images
    displayImages(handles);
    guidata(source, handles);    
end


