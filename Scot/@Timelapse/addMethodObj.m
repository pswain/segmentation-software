function [obj methodObj] = addMethodObj(obj, methodObj)
    % addMethodObj  ---  adds an input method object to the ObjectStruct property of a timelapse

    % Synopsis:    obj =  addMethodObj (obj, methodObj)
    %                            
    % Input:       obj = an object of a Timelapse class
    %              methodObj = an object of a subclass of MethodsSuperClass
    %
    % Output:      obj = an object of a Timelapse class

    %Notes : This function records an input method object in the timelapse
    %        structure ObjectStruct. First it will check if an object of
    %        the same type with identical parameters is already present. If
    %        there is it will return the saved object as the methodObj
    %        output. If not it will assign a new objectnumber to the input
    %        object, save it in the timelape.ObjectStruct property and
    %        return the original methodObj with the modified ObjectNumber.
    
    %Is there already an object of the input type?
    
    if isempty(methodObj.Info)
        methodObj.Info=metaclass(methodObj);
    end
    k=strfind(methodObj.Info.Name,'.');
    package=methodObj.Info.Name(1:k(1)-1);
    className=methodObj.Info.Name(k(end)+1:end);
    equal=false;
    if isfield(obj.ObjectStruct,package)
        if isfield(obj.ObjectStruct.(package),className)
            %Loop through the objects in the class
            for n=1:size([obj.ObjectStruct.(package).(className)],2)
                savedParams=obj.ObjectStruct.(package)(n).(className).parameters;                
                if isequal(savedParams, methodObj.parameters)
                    methodObj=obj.ObjectStruct.(package)(n).(className);
                    equal=true;
                end
            end               
        end
    end
    
    if ~equal
        %There are no identical objects in the obj.ObjectStucture property
        %create a new object with the parameters of the input one (this 
        %will ensure that any other properties of the object that depend on
        %the parameters are correctly initialized)
        %First convert parameters to a cell array
        paramCell=methodObj.param2struct;
        paramCell=paramCell(2);
        paramCell=paramCell{:};
        %Get the method name
        if isempty(methodObj.Info)
            methodObj.Info=metaclass(methodObj.Info);
        end
        methodName=methodObj.Info.Name;
        k=strfind(methodName,'.');
        methodName=methodName(k+1:end);
        %Get a new currentMethod object based on the new parameters, and write
        %it to handles.methodObjects
        methodObj=obj.getobj(methodObj.Info.ContainingPackage.Name,methodName,paramCell{:});        
    end
    