function handles=setParameters(handles)
    % setParameters --- populates the parameter value entry boxes and dropdown lists
    %
    % Synopsis:      handles = setParameters(handles)
    %                        
    % Input:         handles = structure with all gui and timelapse information
    %                
    % Output:        handles = structure with all gui and timelapse information

    % Notes:    Called after a change of method, this function populates
    %           the names of the parameters of the new method and their
    %           current values. For each parameter it displays either a
    %           text entry box or a drop down list - depending on whether a
    %           obj.paramchoices entry is defined for that parameter.
    
    
    fieldList=fields(handles.currentMethod.parameters);
    numToFill=min(size(fieldList,1), 9);%there are only 9 parameter value boxes
    for n=1:numToFill
        set(handles.parameterName(n), 'String',fieldList(n),'Enable', 'On');
        field=fieldList(n);
        field=field{:};
        %Determine if paramChoices is defined for this parameter
        if isfield(handles.currentMethod.paramChoices,field)
            if iscell(handles.currentMethod.paramChoices.(field))
                %entry is a cell array of strings - use this as the 'string' property
                choices=handles.currentMethod.paramChoices.(field);
            elseif ischar(handles.currentMethod.paramChoices.(field))
                %entry is a single string - the name of a package or 'Data'. Get a
                %cell array of the class names in the package or the fields
                %of timelapse.Data
                if strcmp(handles.currentMethod.paramChoices.(field),'Data');
                    choices=fields(handles.timelapse.Data);
                else
                    choices=handles.currentMethod.listMethodClasses(handles.currentMethod.paramChoices.(field));
                end
            end
            
            %Set up the drop down menu
            value=find(strcmp(handles.currentMethod.parameters.(field),choices));%Gives the index to the current parameter value in the list
            set(handles.parameterDrop(n),'string',choices,'Visible','On', 'Value',value);
            set(handles.parameterBox(n),'Visible','Off');            
            
        else%Use the parameter box - for text entry
            parameterValue=handles.currentMethod.parameters.(field);
            set(handles.parameterBox(n),'string',parameterValue,'Enable', 'On','Visible','on');
            set(handles.parameterDrop(n),'Visible', 'off');
        end
        
        %Set the tooltip to the paramHelp entry if defined
        if isfield(handles.currentMethod.paramHelp,fieldList(n))
            set(handles.parameterBox(n),'TooltipString',handles.currentMethod.paramHelp.(fieldList{n}));
        else
            set(handles.parameterBox(n),'TooltipString','No description has been provided for this parameter');
        end
                
        %Determine if paramCall is defined for this parameter
        if isfield(handles.currentMethod.paramCall,field)
            %Was this parameter box previously a paramCall parameter? If
            %not it does not need 
            if strcmp(get(handles.parameterCall(n),'Visible'),'off')
                %Reduce size of the edit box or dropdown to make room for the button
            	oldPosition=get(handles.parameterBox(n),'Position');
                newPosition=oldPosition.*[1 1 .6 1];
                set(handles.parameterBox(n),'Position',newPosition);
                set(handles.parameterDrop(n),'Position',newPosition);
                %Activate function call button
                set(handles.parameterCall(n), 'Visible','on');
            end
        else%paramCall is not defined for this parameter - make sure the dropdown and edit box are the right size
            if strcmp(get(handles.parameterCall(n),'Visible'),'on')
                %This parameter previously had a call button but now does
                %not - need to reset size of the other controls
                oldPosition=get(handles.parameterBox(n),'Position');
                newPosition=oldPosition.*[1 1 1.667 1];
                set(handles.parameterBox(n),'Position',newPosition);
                set(handles.parameterDrop(n),'Position',newPosition);
                %Inactivate function call button
                set(handles.parameterCall(n), 'Visible','off');
            end
        end
        
        
    end
    %Disable any unused parameter boxes.
    if numToFill<9
       for n=numToFill+1:9
          name=['Parameter' num2str(n)];
          set (handles.parameterBox(n),'String', name, 'Enable', 'Off','Visible','On');
          set (handles.parameterDrop(n),'String', name, 'Visible', 'Off');
          set (handles.parameterName(n), 'String', name,'Enable', 'Off');
       end    
    elseif numToFill>9
        %Activate the shuffle parameters button
        set(handles.shuffle,'Enable','On');
    end
    
    %Set the method name
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod.Info);
    end
    k=strfind(handles.currentMethod.Info.Name,'.');
    name=handles.currentMethod.Info.Name(k+1:end);
    set(handles.methodName,'String',name);
    set(handles.description, 'String',handles.currentMethod.description)
    %If the current timepoint has been segmented, activate the initialize
    %current object button - and run button if the method is appropriate
    if size(handles.levelObjects,2)>=handles.Level
        if ~isempty(handles.levelObjects(handles.Level).objects)
            handles.currentObj=handles.levelObjects(handles.Level).objects;
            set(handles.initialize,'Enable','On');
            showMessage('Click initialize button to calculate and display intermediate images for the currently-selecte method');
            %Set the state of the run button, depending on the method
            notToRun={'cellsegmethods';'regionsegmethods';'timepointsegmethods';'runmethods';'timelapsesegmethods'};
            handles.currentMethod.Info=metaclass(handles.currentMethod);
            if any(strcmp(handles.currentMethod.Info.ContainingPackage.Name,notToRun))
                set(handles.run,'Enable','Off');
            else
                set(handles.run,'Enable','On');
            end
        else
            set(handles.initialize,'Enable','Off');
            set(handles.run,'Enable','Off');
        end
    end
    %Record the number of the current object - for use by the restore
    %initial callback.
    handles.initialObject=handles.currentMethod.ObjectNumber;
end