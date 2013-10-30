function handles=extractDataMethod_callback(source,event,handles)
    % extractDataMethod_callback ---  selects new extractdata method
    %
    % Synopsis:        handles=extractDataMethod_callback(handles)
    %
    % Input:           source = handle to the extractDataMethod list
    %                  event = structure, not used
    %                  handles = structure, carries timelapse and gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    Callback for selection of extract data method. Resets
    %           parameter boxes/dropdown menus for the selected method.
    handles=guidata(handles.gui);
    %Redefine the current method
    value=get(source,'Value');
    methodNames=get(source,'String');
    methodName=methodNames{value};
    methodDefined=false;
    %Create or get a method object with the input name
    if isfield(handles,'lastExtractMethod')
        lastMethod=handles.timelapse.methodFromNumber(handles.lastExtractMethod);
        if isa(lastMethod,'methodName')
            handles.currentMethod=lastMethod;
            methdDefined=true;
        end
    end
    if ~methodDefined    
        handles.currentMethod=handles.timelapse.getobj('extractdata',methodName);
    end
    handles=setParameters(handles);
    guidata(handles.gui,handles)