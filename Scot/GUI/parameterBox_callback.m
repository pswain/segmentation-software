function handles=parameterBox_callback(source, eventdata, handles)
    % parameterBox_callback  ---  checks input parameter value and writes to handles.currentMethod.parameters structure
    %              
    % Synopsis:    handles =  parameterBox_callback(source, eventdata, handles)
    %
    % Input:       source = handle to the parameter text box that has been used
    %              eventdata = (unused) structure
    %              handles = structure, carrying all gui information

    %
    % Output:      handles = structure, carrying all gui information

    %Notes:        This callback is used for all of the parameter boxes and
    %              dropdown menus. Uses the checkParams method of the
    %              current method object to evaluate the input parameter.
    %              If the previous parameter value was numeric, converts
    %              the input string to a numeric value if possible.
    %              Otherwise writes directly to the
    %              handles.currentMethod.parameters structure.
    %              
    
    handles=guidata(handles.gui);
    %Get the input parameter value and the index of the parameter that it
    %refers to
    sourceType=get(source,'Style');%the calling uicontrol type
    switch sourceType
        case 'popupmenu'   
            cellArray=get(source,'String');
            inputValue=cellArray{get(source,'Value')};
            paramIndex=(source==handles.parameterDrop);
        case 'edit'
            inputValue=get(source,'String');
            paramIndex=(source==handles.parameterBox);
        case 'pushbutton'            
            paramIndex=handles.parameterCall==source;
            parameterName=get(handles.parameterName(paramIndex),'String');
            funcName=handles.currentMethod.paramCall.(parameterName{:});
            func=str2func(funcName);
            inputValue=func();            
            set(handles.parameterBox(paramIndex),'String',inputValue);
    end
    parameterName=get(handles.parameterName(paramIndex),'String');

    if iscell(parameterName)
        parameterName=char(parameterName);
    end
    %Record the initial state - required for various reasons
    oldMethodNo=handles.currentMethod.ObjectNumber;
    oldValue=handles.currentMethod.parameters.(parameterName);
    oldClasses=handles.currentMethod.Classes;%This is recorded to check if it changes with the new parameter value  
    
    if isnumeric(oldValue)
       try
           inputValue=str2double(inputValue);
       catch
           showMessage(handles, 'Warning: the input should be a number','r');
           set (source,'String', num2str(oldValue));
           return
       end
    end
    %Write the input parameter value to the current method
    handles.currentMethod.parameters.(parameterName)=inputValue;
    %Check the value is OK
    checked=handles.currentMethod.checkParams(handles.timelapse);
    
    if strcmp(checked, 'OK')
        showMessage(handles, 'New parameters checked and are OK');        
    elseif strcmp(checked,'Not checked')
        showMessage(handles, ['Warning: parameter ' parameterName ' could not be checked, no checkParams method',[1 .5 0]]); 
    else
        showMessage(handles, checked,'r');
        handles.currentMethod.parameters.(parameterName)=oldValue;
        handles=setParameters(handles);
        return
    end
    %We are accepting the new parameter value.
    %Need to record a new object with this value in the timelapse.ObjectStruct
    %This will also return a method object with a new object number.
    [handles.timelapse handles.currentMethod]=handles.timelapse.addMethodObj(handles.currentMethod);
    %Record this in the method objects list
    handles.methodObjects(handles.Level).objects=handles.currentMethod;
   
    %If the newly-modified method is a runmethod or a segmethod then it
    %needs to be written to the current object too.
    handles.currentMethod.Info=metaclass(handles.currentMethod);
    if any(strcmp({'runmethods';'timelapsesegmethods';'timepointsegmethods';'regionsegmethods';'cellsegmethods'},handles.currentMethod.Info.ContainingPackage.Name))
        %Only reset runmethod or segmethod if the current object represents
        %the current position in the workflow - this can only be possible
        %if the current timepoint has been segmented or if the current
        %level represents the timelapse
        if size(handles.levelObjects,2)>=handles.Level
            if ~isempty(handles.levelObjects(handles.Level).objects)
                if strcmp('runmethods',handles.currentMethod.Info.ContainingPackage.Name)
                    handles.currentObj.RunMethod=handles.currentMethod;
                else
                    handles.currentObj.SegMethod=handles.currentMethod;
                end
            end
        end
    end
    
    
    %Now check if the change in the parameter value causes a change in
    %currentObj.Classes. If so, we need to redefine the workflow.
    changed=false;
    if isfield(handles.currentMethod.Classes,'classnames');
        for n=1:size(handles.currentMethod.Classes,2)
           if ~iscell(handles.currentMethod.Classes(n).classnames)
               if ~strcmp(handles.currentMethod.Classes(n).classnames,oldClasses(n).classnames)
                   newClassObj=handles.timelapse.getobj(handles.currentMethod.Classes(n).packagenames,handles.currentMethod.Classes(n).classnames);
               changed=1;
               end
           else%Classnames is a cell array of alternative classes - need to check each one
               if ~all(strcmp(handles.currentMethod.Classes(n).classnames, oldClasses(n).classnames))
                  %Not all of the contents of the cell array are identical
                  for a=1:size(handles.currentMethod(n).Classes.classnames,1);
                    newClassObj=handles.timelapse.getobj(handles.currentMethod.Classes(n).packagenames,handles.currentMethod.Classes(n).classnames{a});
                    changed=1;
                  end
               end
           end
        end
    end
    
    
    %Process the workflow on the basis of the change in obj.Classes
    if changed
        %The obj.Classes structure has changed - redefine the workflow.
        if isempty(handles.currentMethod.Info)
            handles.currentMethod.Info=metaclass(handles.currentMethod);
        end
        
        oldLevel=handles.Level;
        
        %Record the number of the current method in the method that called
        %it in the workflow.
        %First get the necessary identifiers.
        callingIndex=handles.workflowTree(handles.Level).callingObjIndex;
        if callingIndex>0%ie if this is not the first method in the workflow
            usedClassIndex=handles.workflowTree(handles.Level).usedClassIndex;
            callingMethodNo=handles.methodObjects(callingIndex).objects.ObjectNumber;
        %Then reset the two recorded versions of the method
        handles.methodObjects(callingIndex).objects.Classes(usedClassIndex).objectnumbers=handles.currentMethod.ObjectNumber;
        fieldName=['Classes(' num2str(usedClassIndex) ').objectnumbers'];
        handles.timelapse.setMethodObjField(callingMethodNo,fieldName, handles.currentMethod.ObjectNumber);
        end
        %Redefine the workflow, starting with the first object called by
        %the current method. The level of that object should be the same as
        %the level of the first object called by the previous version of
        %the current method.

        %First need to set handles.Level to the correct position. This will
        %be the level of the first method called by the previous version of
        %the current object
        
        %handles.workflowTree.callingObjIndex==handles.Level - finds indices
        %to all objects called by the previous version of the current
        %method. Then get the one for which
        %handles.workflowTree.usedClassIndex==1;
        
        %Then set handles.Level to that index.
        %Record the current workflow to allow you to retrieve any objects
        %that were called by any methods above the current method. Write a
        %repair workflow function to achieve that.
        callingObjIndex=handles.Level;
        handles.Level=find([handles.workflowTree.usedClassIndex]==1 & [handles.workflowTree.callingObjIndex]==handles.Level);
        handles.Level=handles.Level(1);%In the case of alternatives the previous line will have output a vector - use the first entry of that vector
        for c=1:size(handles.currentMethod.Classes,2)
            handles=followWorkflow(handles, handles.currentMethod.Classes(c).packagenames,handles.currentMethod.Classes(c).classnames, callingObjIndex,c);
            handles.Level=handles.Level+1;
        end
        handles=highlightWorkflow(handles);
        %Need to repair the workflow now
        %The loop above may have deleted some items from the workflow.
        %use the information in handles.workflowTree to do that.       
        handles.Level=oldLevel;
        
        %In addition to redefining the method objects in the workflow -
        %also need to remove any level objects from levels that have been
        %affected (ie are below the current level
        handles.levelObjects(handles.Level:end)=[];
        
        %Update the GUI
        set(handles.workflowList,'String',handles.workflowNames);
        set(handles.workflowList,'Value',handles.Level);
    end
    
    
    %Also need to make sure that any methods that call the current method
    %will refer to the altered one, not the original one when the
    %segmentation is running.
    %Find the index to the calling object
    callingObjIndex=handles.workflowTree(handles.Level).callingObjIndex;
    if callingObjIndex>0%ie if the current object is not at the top of the workflow
        thisClassIndex=handles.workflowTree(handles.Level).usedClassIndex;
        oldObjectNos=handles.methodObjects(callingObjIndex).objects.Classes.objectnumbers;
        newObjectNos=oldObjectNos;
        %Find the entry for this object in the calling object's Classes
        %structure and set the new value in newObjectNos
        logIndex=[handles.methodObjects(callingObjIndex).objects.Classes(thisClassIndex).objectnumbers]==oldMethodNo;
        newObjectNos(logIndex)=handles.currentMethod.ObjectNumber;
        %Write the modified object numbers array to the calling class in
        %handles.methodObjects
        handles.methodObjects(callingObjIndex).objects.Classes(thisClassIndex).objectnumbers=newObjectNos;
        %Set correct object number in the version of the object saved in
        %timelapse.ObjectStruct
        fieldName=['Classes(' num2str(thisClassIndex) ').objectnumbers'];
        callingObjNumber=handles.methodObjects(callingObjIndex).objects.ObjectNumber;
        handles.timelapse.setMethodObjField(callingObjNumber, fieldName, newObjectNos);  
    end
    
    %Clear the required images and fields for this method - in case the change in the
    %parameter value alters any of them.
    for n=1:size(handles.currentMethod.requiredImages,1)
       if strcmp(handles.currentMethod.requiredImages(n),{'Bin'})
           if isfield(handles.currentObj.RequiredImages,'Bin') 
                if size(handles.currentObj.RequiredImages.Bin,3)>1
                    handles.currentObj.RequiredImages.Bin(:,:,3)=[];
                else
                    handles.currentObj.RequiredImages=rmfield(handles.currentObj.RequiredImages,'Bin');
                end
           end
       else
           if isfield(handles.currentObj.RequiredImages,handles.currentMethod.requiredImages(n)) 
                handles.currentObj.RequiredImages=rmfield(handles.currentObj.RequiredImages,handles.currentMethod.requiredImages(n));  
           end
       end
    end
    %If this timepoint has been segmented (ie if the currentObj represents
    %a real object at the current level - activate the button to allow
    %initialization of the fields
    if size(handles.levelObjects,2)>=handles.Level
        if ~isempty(handles.levelObjects(handles.Level).objects)
            set(handles.initialize,'Enable','On');
            showMessage('Click initialize button to calculate and display intermediate images for the currently-selecte method');
        else
            set(handles.initialize,'Enable','Off');
        end
    end
    %Refresh the display
    handles=displayImages(handles);    
    guidata(handles.gui, handles);
end