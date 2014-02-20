function methodList=listMethodClasses(package)
    % listMethodClasses --- genrates a list of the method classes in the package with the input name
    %
    % Synopsis:  methodList = listMethodClasses(package)
    %
    % Input:     package = string, the name of a package
    %
    % Output:    methodList = cell array of strings, the names of all 
    %            method classes in the input package

    % Notes:     This function is used to populate the list of available
    %            methods in the GUI or from a method's checkParams method
    %            to check parameters that specify which method from a
    %            package should be used. If the input package name is not a
    %            Scot method package then the output methodList is empty.

    %Problem is to avoid superclasses in this list - the method classes all
    %have no subclasses - but may have superclasses.
    %No way I can find to identify subclasses - so loop through the classes
    %looking at their superclasses.
    
    
    metaInfo=meta.package.fromName(package);
    nClasses=size(metaInfo.Classes,1);%The number of classes in the package.
    superClasses=struct('classNames',cell(1),'sClassNames',cell(size(nClasses,1)), 'isMethod',false(size(nClasses,1)));% a structure array. Each element contains a cell array of superclass names
    for n=1:nClasses;
        thisClass=metaInfo.Classes(n);
        thisClass=thisClass{:};
        k=strfind(thisClass.Name,'.');
        thisClassName=thisClass.Name(k(end)+1:end);
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
    end
    
    %Now test each class to see if it has any subclasses - nested loop
    for n=1:nClasses%Loop through the classes to check - is class number n a subclass of any of the others?
        for c=1:nClasses%Loop through the classes to check - is class number c a superclass of class number n?
            cClass=metaInfo.Classes(c);
            cClass=cClass{:};
            if length(superClasses)>=n
                for s=1:length(superClasses(n).sClassNames)%Loop through the superclasses of class n to see if c is one of them
                    if strcmp(cClass.Name,superClasses(n).sClassNames(s))
                        %This c class is a superclass of this n class
                        superClasses(1).isMethod(c)=false;
                    end
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
            thisClass=metaInfo.Classes(n);
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
    %Make a cell array
    methodIndices=[superClasses(1).isMethod];
    methodList=superClasses(1).classNames(methodIndices);
end