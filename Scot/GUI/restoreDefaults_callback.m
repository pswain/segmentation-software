function handles=restoreDefaults_callback(source, eventdata, handles)
    % restoreDefaults_callback  ---  Reverts the parameters of the current method to their defaults
    %              
    % Synopsis:    handles =  restoreDefaults_callback(source, eventdata, handles)
    %
    % Input:       source = handle to the calling uicontrol
    %              eventdata = (unused) structure
    %              handles = structure, carrying all gui information

    %
    % Output:      handles = structure, carrying all gui information

    % Notes:       This callback is run when the defaults button is
    %              clicked. It replaces the currentMethod with a version of
    %              the same method but with its default parameters.
    
    handles=guidata(handles.gui);
    handles.currentMethod.Info=metaclass(handles.currentMethod)
    name=handles.currentMethod.Info.Name;
    func=str2func(name);
    tempMethod=func();
    parameters=tempMethod.param2struct;
    k=strfind(name,'.');
    package=name(1:k-1);
    name=name(k+1:end);    
    handles.currentMethod=handles.timelapse.getobj(package,name,parameters{:});    
    handles=setParameters(handles);  
    set(handles.initialize,'Enable','on');
    showMessage('Set method to default parameters. Click show intermediate images button to show images created using these parameters');
    
    guidata(handles.gui,handles);