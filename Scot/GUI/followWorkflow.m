function handles=followWorkflow(handles, packageName, className, callingObjIndex, usedClassIndex)
    % followWorkflow ---  defines the segmentation workflow for segmentations that have not yet been run by following all methodObj.Classes structures
    %
    % Synopsis:        handles = followWorkflow(handles, packageName, className, callingObjIndex, usedClassIndex)
    %
    % Input:           handles = structure, holds all gui information
    %                  packageName = string, name of the package of the current class in the workflow to be followed
    %                  className = string or cell array of strings, name of the class or alternative classes in the workflow to be followed
    %                  callingObjIndex = the index in the workflow of the object that uses the current object
    %                  usedClassIndex = the index in callingObject.Classes of the method currently being added
    %
    % Output:          handles=structure, holds all gui information
    
    % Notes:    This function repeatedly calls itself until the workflow is
    %           complete - ie all classes used by other classes in the
    %           workflow have been added to the workflow entries in
    %           handles. The second last input (callingObjIndex) should be
    %           zero if packageName + className refer to the first item in
    %           a workflow (normally a timelapse object). If the calling
    %           object uses more than one class then the last input is the
    %           index to the class currently being considered in the
    %           calling object's Classes structure.
    %   handles.historySize = the number of items in the workflow 
    %   handles.workflowNames = the names of each object in the workflow
    %   handles.workflowLevels = the type of level object ('OneCell', 'Region', 'Timepoint' or 'Timelapse') that each object either is or has worked on.
    %   handles.workflowResultImageNames = the name of the image or other field that each method has written its result to.
    %   handles.levelObjects = the handles to the level objects worked on at each stage of the workflow
    %   handles.workflowAlternatives = logical array recording if the methods in the workflow are alternatives, one of which will eventually be used if successful
    %   handles.methodObjects = method objects at each level in the workflow
    %   handles.workflowTree = carries details of which objects call which others. Entry for each object has two fields: .callingObjIndex and .usedClassIndex - as in the inputs to this function
    
    %First clear all workflow entries below the current level.
    %handles.Level should be the index to the object currently being
    %considered (packageName.className) in the work flow arrays.
    if handles.Level<handles.historySize
        handles.workflowNames(handles.Level:end)=[];
        handles.workflowLevels(handles.Level:end)=[];
        handles.workflowResultImageNames(handles.Level:end)=[];
        handles.levelObjects(handles.Level:end)=[];
        handles.workflowAlternatives(handles.Level:end)=[];
        handles.methodObjects(handles.Level:end)=[];
        handles.workflowTree(handles.Level:end)=[];
    end
    
    if any(strcmp(packageName, {'runmethods','Level'}))
        %If sent a level object, define the current method as it's run
        %method. Also define 'level', to be used to populate
        %handles.workflowLevels - list of level object types. If sent a
        %runmethod - define 'level' to the object it works on.
        switch className
            case {'Timelapse','RunTLSegMethod'}               
            level='timelapse';
            currentMethod=handles.timelapse.getobj('runmethods','RunTLSegMethod');                     
            case {'RunTpSegMethod','Timepoint'}
            level='timepoint';
            currentMethod=handles.timelapse.getobj('runmethods','RunTpSegMethod');
            case {'RunRegionSegMethod','Region'}
            level='region';
            currentMethod=handles.timelapse.getobj('runmethods','RunRegionSegMethod');
            case {'RunCellSegMethods','OneCell'}
            level='onecell';
            currentMethod=handles.timelapse.getobj('runmethods','RunCellSegMethods');           
        end
    else%The input object is not a level object or runmethod. Define the workFlowLevels
        %entry as being the same as the previous level. Create a method
        %object (or objects) of the input type
        level=handles.workflowLevels{callingObjIndex};
        if iscell(className)%There are alternative classes here - className is a cell array of strings
            for c=1:size(className,1)
                currentMethod{c}=handles.timelapse.getobj(packageName, className{c});
            end
        else
        currentMethod=handles.timelapse.getobj(packageName,className);
        end
    end
    
    %Define the entry for the current level in the handles.levelObjects
    %array. This will only be possible if the current level represents the
    %timelapse object
    if strcmp(level,'timelapse')
        handles.levelObjects(handles.Level).objects=handles.timelapse;
    end
    %Write the entries for the current method in the handles workflow
    %arrays.
    %Name
    info=metaclass(currentMethod);
    name=info.Name;
    
    if ~strcmp(name,'cell')
        %The currentMethod is a single method. Record its details in the
        %handles workflow entries.
        %Remove package name from name
        k=strfind(name,'.');
        name=name(k(end)+1:end);
        handles.workflowNames(handles.Level)={name};
        %Level object type
        handles.workflowLevels(handles.Level)={level};
        %Result image type
        handles.workflowResultImageNames(handles.Level)={currentMethod.resultImage};
        %Method object
        handles.methodObjects(handles.Level).objects=currentMethod;
        %Tree
        handles.workflowTree(handles.Level).callingObjIndex=callingObjIndex;
        handles.workflowTree(handles.Level).usedClassIndex=usedClassIndex;
        %Alternatives - there are not alternative methods here
        handles.workflowAlternatives(handles.Level)=0;
    else
        %currentMethod is a cell array of objects - there are alternative
        %methods that can be used depending on their results - all need to
        %be added to workflow variables but also need to record that they
        %are alternatives.
        thisAlternative=max(handles.workflowAlternatives)+1;
        for m=1:size(currentMethod,2)
            handles.workflowAlternatives(handles.Level-1+m)=thisAlternative;
            info=metaclass(currentMethod{m});
            name=info.Name;
            k=strfind(name,'.');
            name=name(k(end)+1:end);
            %Define name in workflowNames with html formatting to highlight
            %with green background
            handles.workflowNames(m+handles.Level-1)={name};%{['<HTML><BODY bgcolor="green">' name '</Body</html>']};            
   %         handles.workflowNames(m+handles.Level-1)={['<HTML><BODY bgcolor="green">' name '</Body</html>']};
            %Level object type
            handles.workflowLevels(m+handles.Level-1)={level};
            %Result image type
            handles.workflowResultImageNames(m+handles.Level-1)={currentMethod{m}.resultImage};
            %Method object
            handles.methodObjects(m+handles.Level-1).objects=currentMethod{m};
             %Tree
            handles.workflowTree(m+handles.Level-1).callingObjIndex=callingObjIndex;
            handles.workflowTree(m+handles.Level-1).usedClassIndex=usedClassIndex;

        end
        %Reset handles.Level to the level of the last object added.
        handles.Level=m+handles.Level-1;
        
    end
    %Change the history size based on the newly-added object(s)
    handles.historySize=handles.Level;
    %The input class(es) is(are) now recorded in the workflow.
    
    %Write its(their) object number(s) to the Classes structure of the object that
    %required it (if there is one, ie if the input class isn't the first
    %item in the workflow)
    if callingObjIndex>0
        if size(handles.methodObjects(callingObjIndex).objects.Classes,2)==1
            %The calling class only uses one other method class - ignore
            %whatever was input to usedClassIndex
            usedClassIndex=1;
        end
        %Check if currentMethod is a single method object or a cell array
        %of methods
        if size(currentMethod,2)>1
            %In this case generate a vector of object numbers,
            %corresponding to the entries in the cell array of alternative
            %methods.
            for m=1:size(currentMethod,2)
               handles.methodObjects(callingObjIndex).objects.Classes(usedClassIndex).objectnumbers{m}=currentMethod{m}.ObjectNumber;
               %Need to add/alter this field also in the version of this
               %object saved in timelapse.ObjectStruct
               callingObjNumber=handles.methodObjects(callingObjIndex).objects.ObjectNumber;
               fieldName=['Classes(' num2str(usedClassIndex) ').objectnumbers{' num2str(m) '}'];
               handles.timelapse.setMethodObjField(callingObjNumber, fieldName, currentMethod{m}.ObjectNumber);

            end
        else
            if iscell(currentMethod)%In case it's a cell array containing only one entry
               currentMethod =currentMethod{:};
            end
            %Write the object number to the method stored in
            %handles.methodObjects
            handles.methodObjects(callingObjIndex).objects.Classes(usedClassIndex).objectnumbers=currentMethod.ObjectNumber;
            %Need to add/alter this field also in the version of this
            %object saved in timelapse.ObjectStruct            
            callingObjNumber=handles.methodObjects(callingObjIndex).objects.ObjectNumber;
            try
            savedClasses=handles.timelapse.getMethodObjField(callingObjNumber,'Classes');
            catch
                disp('Debug point in followWorkflow');
            end
%             if ~isfield(savedClasses,'objectnumbers');
%                 handles.timelapse.setMethodObjField(callingObjNumber, 'Classes.objectnumbers', []);
%             end
         
            fieldName=['Classes(' num2str(usedClassIndex) ').objectnumbers'];
            handles.timelapse.setMethodObjField(callingObjNumber, fieldName, currentMethod.ObjectNumber);
        end
    end
    
    %Next need to see if the method
    %creates any other methods when it is run or initialized. This
    %information is read from currentMethod.Classes.
    %First record the current level so we can return to that after adding
    %to the list.
    oldLevel=handles.Level;
    for o=1:size(currentMethod,2)%Loop, in case currentMethod is a cell array of objects of alternative classes
        if iscell(currentMethod)
            method=currentMethod{o};
            thisObjIndex=handles.Level-size(currentMethod,2)+o;
        else
            method=currentMethod;
            thisObjIndex=handles.Level;
        end
        
        for n=1:size(method.Classes,2)%Loop through the classes used by the current method
            if ~isempty(fields(method.Classes))%ie, does this method use any other classes
                packageName=method.Classes(n).packagenames;
                className=method.Classes(n).classnames;
                %Call this function, sending the details of the object type
                handles.Level=handles.Level+1;
                handles=followWorkflow(handles, packageName, className, thisObjIndex, n);
            end
        end
    end
    handles.Level=oldLevel;


end

