function handles=populateMethod(handles)
    % populateMethod --- identifies the available method classes in the current package and populates the methods menu
    %
    % Synopsis:  handles=populateMethod(handles)
    %
    % Input:     handles = structure carrying all the information used by the GUI
    %
    % Output:    handles = structure carrying all the information used by the GUI

    % Notes:     This function is called after a change to the current
    %            level object or a change to the selected package. First
    %            the package menu value is set to the package of the
    %            current method. If that is a run method then the package
    %            menu and methods menus are disabled - can only have the
    %            one run method acting on a level object. If the current
    %            method belongs to a different package then the available
    %            methods in the package are found and used to populate the
    %            method list. Then for all methods the parameter fields
    %            are populated. Finally the state of the run buttons is
    %            decided. Depending on the package, the run button should
    %            be enabled or disabled.
    
    %Set the package menu to the package of the current method
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
    k=strfind(handles.currentMethod.Info.Name,'.');
    methodName=handles.currentMethod.Info.Name(k(end)+1:end);
    %Now handle things differently if the current method is a run method or
    %another type.
    if strcmp(handles.currentMethod.Info.ContainingPackage.Name,'runmethods')
        packageList=get(handles.packageMenu,'String');
        thisPackageIndex=find(~cellfun('isempty',(strfind(packageList,'runmethods'))));
        set(handles.packageMenu,'Value',thisPackageIndex);        
        %set(handles.methodsMenu, 'Enable','off');               
    else
        set(handles.packageMenu,'Enable','on');
        packageList=get(handles.packageMenu,'String');
        thisPackageIndex=find(~cellfun('isempty',(strfind(packageList,handles.currentMethod.Info.ContainingPackage.Name))));
        set(handles.packageMenu,'Value',thisPackageIndex);      
        set(handles.methodsMenu, 'Enable','on');
    end
    %Need to get a list of all the method classes in this package
    %Problem is to avoid superclasses in this list - the method classes all
    %have no subclasses - but may have superclasses
    %No way I can find to identify subclasses - so loop through the classes
    %looking at their superclasses.
    nClasses=size(handles.currentMethod.Info.ContainingPackage.Classes,1);%The number of classes in the package.
    superClasses=struct('classNames',cell(1),'sClassNames',cell(size(nClasses,1)), 'isMethod',false(size(nClasses,1)));% a structure array. Each element contains a cell array of superclass names
    for n=1:nClasses;
        thisClass=handles.currentMethod.Info.ContainingPackage.Classes(n);
        thisClass=thisClass{:};
        k=strfind(thisClass.Name,'.');
        thisClassName=thisClass.Name(k(end)+1:end);
        if strcmp(thisClassName, methodName)
            methodIndex=n;
        end
        superClasses(1).classNames{n}=thisClassName;
        %all method classes in a package should have at least one superclass - 
        %If thisClass is the package superclass then one of the superclasses
        %will be MethodsSuperClass. If a class has no superclass then it isn't
        %a method class.
        if ~isempty(thisClass.SuperClasses)
            sNames=cell(size(thisClass.SuperClasses{:},1));    
            for s=1:size(thisClass.SuperClasses{:},1)
                sClass=thisClass.SuperClasses{s};
                sNames(s)={sClass.Name};        
            end
            superClasses(n).sClassNames=sNames;
            superClasses(1).isMethod(n)=true;%just to initialize this - will check it later
        else
            superClasses(1).isMethod(n)=false;
        end
        %Write the .description string to the method description box
        set(handles.description,'String', handles.currentMethod.description);
    end
    %Now test each class to see if it has any subclasses - nested loop
    for n=1:size(superClasses,2)%Loop through the classes to check - is class number n a subclass of any of the others?
        for c=1:nClasses%Loop through the classes to check - is class number c a superclass of class number n?
            cClass=handles.currentMethod.Info.ContainingPackage.Classes(c);
            cClass=cClass{:};
            for s=1:size(superClasses(n).sClassNames)%Loop through the superclasses of class n to see if c is one of them
                if strcmp(cClass.Name,superClasses(n).sClassNames(s))
                    %This c class is a superclass of this n class
                    superClasses(1).isMethod(c)=false;
                end
            end
        end    
    end
    %For the classes that are not superclasses - now check that they are
    %ultimately subclasses of MethodSuperClass (THIS LOOP CAN PROBABLY BE
    %INCORPORATED INTO ONE OF THE ONES ABOVE)
    for n=1:nClasses
        if superClasses(1).isMethod(n)%this one is not a superclass  
            %sClassNumber=1;The loop only handles cases in which there is only one superclass per class
            checked=false;
            thisClass=handles.currentMethod.Info.ContainingPackage.Classes(n);
            thisClass=thisClass{:};
            while ~checked
                %Go through the class heirarchy until you get to a subclass of
                %MethodsSuperClass
                if ~isempty(thisClass.SuperClasses)
                    thisSClass=thisClass.SuperClasses(1);
                    thisSClass=thisSClass{:};
                    if strcmp(thisSClass.Name, 'MethodsSuperClass')
                        checked=true;%the class is a subclass of MethodsSuperClass - leave isMethod as true and exit the while loop
                    else
                        thisClass=thisSClass;%Check the superclass in the next loop iteration
                    end           
                else%thisclass has no superclass - cannot be a method class
                    superClasses(1).isMethod(n)=false;
                    checked=1;
                end          
            end      
        end
    end
    %Make a cell array for populating the menu
    methodIndices=[superClasses(1).isMethod];
    methodClassList=superClasses(1).classNames(methodIndices);
    %Pass this info to the GUI
    set(handles.methodsMenu,'String',methodClassList);
    methodListIndex=find(~cellfun('isempty',(strfind(methodClassList,methodName))));
    set(handles.methodsMenu,'Value', methodListIndex);
   
    
    %Populate the parameter fields
    setParameters(handles);
    
    %Set the state of the run button
    switch (handles.currentMethod.Info.ContainingPackage.Name)
        case {'cellsegmethods','regionsegmethods','timepointsegmethods','timelapsesegmethods','runmethods'}
            %These classes will continue to completion when run - no point
            %in having the limited run button enabled
            set(handles.run,'Enable','Off');
        case {'splitregion' ,'findregions', 'findcentres'}
            set(handles.run, 'Enable', 'On');        
    end
end
