function [handles]=methodsMenu_callback(source, eventdata, handles)
    handles=guidata(handles.gui);
    showMessage(handles,'');
    %Get the name of the selected method and its package
    methodIndex=get(source,'Value');
    list=get(source,'String');
    methodName=list(methodIndex);
    packageIndex=get(handles.packageMenu,'Value');
    packageList=get(handles.packageMenu,'String');
    packageName=packageList(packageIndex);
    methodName=methodName{:};
    packageName=packageName{:};
    %reset the current method to the selected one
    if isempty(handles.currentObj.Timelapse)
        handles.currentObj.Timelapse=handles.timelapse;
    end
    handles.currentMethod=handles.currentObj.Timelapse.getobj(packageName, methodName);
    %Populate the parameter fields
    setParameters(handles);
    %Display the method desciption
    set(handles.description,'String', handles.currentMethod.description);
    %Activate the run button
    set(handles.run,'Enable', 'on');
    guidata(handles.gui, handles);
end