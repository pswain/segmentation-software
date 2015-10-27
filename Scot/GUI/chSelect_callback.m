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
    end
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
        %Also need to a add the identifier for the main image set if it's
        %not already there
        if ~iscell(inputs)
            inputs={inputs};
        end              
        
        
        %Get the main identifier
        for ch=1:length(handles.timelapse.ImageFileList)
            if strcmp(handles.timelapse.ImageFileList(ch).label,'main')
                main=handles.timelapse.ImageFileList(ch).identifier;
            end
        end
        %Add the main identifier if it's not there
        if ~any(strcmp(main,inputs))
            inputs{end+1}=main;
        end
        %Add the new identifier
        inputs{end+1}=identifier;
        
        set(source,'String',inputs, 'Value',(size(inputs,2)));        
    else%User has selected an existing channel
        handles.rawDisplay=input;        
    end
    handles=displayImages(handles);
    guidata(handles.gui,handles);
    
        
end