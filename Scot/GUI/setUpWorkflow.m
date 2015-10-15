function handles=setUpWorkflow(handles)
    % setUpWorkflow ---  defines the information required to keep track of the segmentation workflow and sets these in the relevant GUI controls
    %
    % Synopsis:        handles=setUpWorkflow(handles)
    %
    % Input:           handles=structure, holds all gui information
    % 
    % Output:          handles=structure, holds all gui information
    
    % Notes:    This function is only for use in editing segmentations. For
    % setting up a new workflow before segmentation has been run use the
    % alternative function setUpNewWorkflow. This function defines the
    % following components of the handles structure using information
    % stored in handles.timelapse.TrackingData.
    %
    %   handles.historySize = the number of items in the workflow 
    %   handles.workflowNames = the names of each object in the workflow
    %   handles.workflowLevels = the type of level object ('OneCell', 'Region', 'Timepoint' or 'Timelapse') that each object either is or has worked on.
    %   handles.workflowResultImageNames = the name of the image or other field that each method has written its result to.
    %   handles.levelObjects = the handles to the level objects worked on at each stage of the workflow
    %   handles.methodObjects = method objects at each level in the workflow
    %   handles.workflowTree = carries details of which objects call which others. Entry for each object has two fields: .callingObjIndex and .usedClassIndex

    
    %Set the history size and clear the workflow
    %Make sure there are no zero (preallocated) entries left in the method
    %object list
    handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj==0)=[];   
    handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).levelobj(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).levelobj==0)=[];   

    handles.historySize=size(handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj,2);
    %Initialize workflow entries
    handles.workflowNames=cell(handles.historySize,1);%String array for populating the workflow list
    handles.workflowLevels=cell(handles.historySize,1);%string array - type of level object on which each method has worked
    handles.workflowResultImageNames=cell(handles.historySize,1);%string array - the type of image that each method writes its result to
    handles.levelObjects=struct('objects',{});%This will store the level objects
    handles.methodObjects=struct('objects',{});%This will store the level objects
    handles.workflowTree=[];
    handles.workflowTree.callingObjIndex=0;
    handles.workflowTree.usedClassIndex=0;

    %Set the first entry in the workflow - handles.timelapse
     handles.workflowNames{1}='RunTLSegMethod';%The run method for the timelapse segmentation
     handles.workflowLevels{1}='Timelapse';
     handles.workflowResultImageNames{1}='Result';
     handles.levelObjects(1).objects=handles.timelapse;
     handles.methodObjects(1).objects=handles.timelapse.RunMethod;
    %Loop through the remaining entries in the recorded history
    for n=2:handles.historySize
        %Get level and method objects corresponding to this entry in the
        %recorded history
        methodNum=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).methodobj(n);
        levelNum=handles.timelapse.TrackingData(handles.timelapse.CurrentFrame).cells(handles.trackingnumber).levelobj(n);
        method=handles.timelapse.methodFromNumber(methodNum);
        %This if statement to deal with the situation where the methodNum
        %is not present in the timelapse - can result from a bug in the
        %segmentation software, now fixed but there may be more.
        if isempty(method)
            if handles.Level>n-1
                handles.Level=n-2;
            end
            break;
        end
        %Get the appropriate level object.
        levelObj = findObject(handles.timelapse, levelNum, handles.levelObjects);
        %Set handles.workflowNames entry
        info=metaclass(method);
        name=info.Name;
        %remove the package name from the class name and record it seperately        
        k=strfind(name,'.');
        name=name(k(end)+1:end);    
        handles.workflowNames(n)={name};
        %Set handles.workflowLevels entry
        if isa(levelObj,'Timelapse')
            level='Timelapse';
        elseif isa(levelObj, 'Timepoint')
            level='Timepoint';
        elseif isa(levelObj, 'Region')
            level='Region';
        elseif isa(levelObj, 'OneCell')
            level='OneCell';
        end
        handles.workflowLevels{n}=level;
        %Set handles.workflowResultImageNames entry
        handles.workflowResultImageNames{n}=method.resultImage;
        %Set level objects entry       
        handles.levelObjects(n).objects=levelObj;
        %Set method objects entry
        handles.methodObjects(n).objects=method;
        %Set the workflowtree entry
        %Loop through all previous workflow entries to find the one(s) that
        %call this method object
        callingObjIndex=[];
        usedClassIndex=[];
        for m=1:n-1
           classes=handles.methodObjects(m).objects.Classes;
           if ~isempty(fields(classes))
               if isfield(classes,'objectnumbers')
                calls=classes.objectnumbers==method.ObjectNumber;
               
               
                if any(calls)
                callingObjIndex(size(callingObjIndex,2)+1)=m;
                usedClassIndex(size(usedClassIndex,2)+1)=find(calls);
                end
               else
                   %the method class at position m in the list does not
                   %list any object numbers.
                   %Assume that it calls the object at position n.
                   callingObjIndex=1;
                   usedClassIndex=1;
                   
               end
           end
        end
        %If there is more than one calling class, use the last one found in
        %the workflow
        try
        handles.workflowTree(n).callingObjIndex=callingObjIndex(end);
        catch
            disp('stop');
        end
        handles.workflowTree(n).usedClassIndex=usedClassIndex(end);        
    end
    %Add the post-history - any methods that have been applied to the timelapse
    %after segmentation
    numMethodObjects=size(handles.methodObjects,2);
    if ~isempty(handles.timelapse.PostHistory)
    for n=1:size(handles.timelapse.PostHistory.objnumbers,2)
       method=handles.timelapse.methodFromNumber(handles.timelapse.PostHistory.objnumbers(n));
       handles.methodObjects(n+numMethodObjects).objects=method;
       info=metaclass(method);
       name=info.Name;
       %Remove package name from name
       k=strfind(name,'.');
       name=name(k(end)+1:end);
       handles.workflowNames(n+numMethodObjects)={name};
       handles.workflowLevels(n+numMethodObjects)={'timelapse'};
       handles.workflowResultImageNames(n)={'Result'};
       handles.levelObjects(n+numMethodObjects).objects=handles.timelapse;
    end
    end
   
%Update the GUI
set(handles.workflowList,'String',handles.workflowNames);
set(handles.workflowList,'Value',handles.Level);
end
