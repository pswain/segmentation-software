function handles=extractData_callback(source,event,handles)
    % extractData_callback ---  resets gui to allow data extraction
    %
    % Synopsis:        handles=extractData_callback(handles)
    %
    % Input:           source = handle to the extractData button
    %                  event = structure, not used
    %                  handles = structure, carries timelapse and gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Called by clicking on the extract data button. Resets the
    %           current method to the last used extractdata method (or the
    %           first on the list). Makes the first parameter box invisible
    %           and replaces it with a dropdown menu of possible
    %           extractdata methods. Activates the run data extraction
    %           button.



handles=guidata(handles.gui);
%This button is clicked either when setting up data extraction or when
%returning to timelapse editing.
if strcmp(get(handles.extractDataMethod,'Enable'),'off');%User wants to set up data extraction
    set(handles.extractDataMethod,'Enable','on');
    set(handles.run,'String','Run data extraction','BackgroundColor',[0.6 0.6 1],'TooltipString','Click to extract data using the current method and parameters','Enable','on');
    set(handles.extractdata,'String','Return','TooltipString','Return to editing timelapse segmentation and tracking','BackgroundColor', [0.7020 0.7020 .7020]);
    handles.storedMethod=handles.currentMethod;
    if ~isfield(handles,'lastExtractMethod')
        %No previous extraction method object is defined. Use the first on the list
        methods=get(handles.extractDataMethod,'String');
        handles.currentMethod=handles.timelapse.getobj('extractdata',(methods{1}));
    else
        handles.currentMethod=handles.timelapse.methodFromNumber(handles.lastExtractMethod);
    end
else%User wants to return to timelapse segmentation editing
    set(handles.extractDataMethod,'Enable','off');    
    set(handles.run,'String','Run method','TooltipString','Run this method to see immediate result image. This will not overwrite saved data.','BackgroundColor', [.7 1 .7]);
    set(handles.extractdata,'String','Extract data','TooltipString','Click to extract data from a segmented timelapse.','BackgroundColor', [0.6 0.6 1]);
    handles.currentMethod=handles.storedMethod;
end
handles=setParameters(handles);
guidata(handles.gui,handles)
end