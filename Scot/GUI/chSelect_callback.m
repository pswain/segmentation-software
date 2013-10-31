function handles=chSelect_callback(source, event, handles)   
    % chSelect_callback --- segments and tracks a new timelapse     
    %
    % Synopsis:  handles = chSelect_callback (source, eventdata, handles)
    %
    % Input:     source = handle to the calling uicontrol
    %            event = structure, not used            
    %            handles = structure carrying segmentation and gui data
    %                                               
    % Output:    handles = structure carrying segmentation and gui data
    %
    % Notes:     This is the callback for the channel selection menu in the
    %            timepoint image display panel. Allows selection of
    %            different channels for display and adding of new ones.
    handles=guidata(handles.gui);
    value=get(source,'Value');
    inputs=get(source,'String');
    if iscell(inputs)
        input=inputs{value};
    else
        input=inputs;
    if strcmp(input,'Add channel')
        %Open a dialogue to get the identifier string (this will be
        %replaced when accessing data from an Omero database)
        identifier = inputdlg('Filename contains...','New channel',1,{'GFP'});
        if iscell(identifier)
            identifier=identifier{:};
        end
        %Load images based on the identifier
        handles=loadRawImages(handles, handles.timelapse,identifier);
        handles.rawDisplay=identifier;
        %Add the identifier as an option to the channel selection menu
        if ~iscell(inputs)
            inputs={inputs};
        end
        inputs{end}=identifier;
        inputs{end+1}='Add channel';
        set(source,'String',inputs, 'Value',(size(inputs,1)-1));        
    else%User has selected an existing channel
        handles.rawDisplay=input;        
    end
    handles=displayImages(handles);
    guidata(handles.gui,handles);
    
        
end