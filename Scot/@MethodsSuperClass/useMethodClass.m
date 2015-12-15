function [inputObj fieldHistory] = useMethodClass(obj,inputObj, fieldHistory, fieldName, packageName, methodName, varargin)
    % useMethodClass --- Creates, initializes and runs an object of the input method class name and package
    %
    % Synopsis:  [inputObj fieldHistory] = useMethod(inputObj, fieldHistory, fieldName, packageName, methodName)  
    %            [inputObj fieldHistory] = useMethod(inputObj, fieldHistory, fieldName, packageName, methodName varargin)  
    %                        
    % Input:     obj = an object of  method class
    %            inputObj = an object of a level class
    %            fieldHistory = structure, record of the method classes that have already been used to initialize fields of inputObj
    %            fieldName = string, the name of the field in inputObj.requiredFields or inputObj.requiredImages that the method class is being used to define
    %            packageName = string, the name of the package of the method to be run
    %            methodName = string, the name of the method to be run
    %            varargin = cell array, parameters for the method class in standard Matlab format
    %
    % Output:    inputObj = the modified, input level class object
    %            fieldHistory = structure, updated record of all method classes that so far been used to initialize fields of inputObj

    % Notes:     Called from initializeFields methods of method classes.
    %            This method was written to simplify those methods and
    %            should be called whenever another method class is to be
    %            used to initialize a field.
    
    fieldIndex=size(fieldHistory,2) +1;%this is the index to the new entry that will be created in fieldHistory to record use of the method 'methodName'
    fieldHistory(fieldIndex).fieldnames=fieldName;
    %Define the timelapse - needed for call to getobj
    if isa (inputObj,'Timelapse')
        tl=inputObj;
    else
        tl=inputObj.Timelapse;
    end
    %Create or retrieve an object of the input class
    %If the object's number is already defined in the obj.Classes variable
    %then use that, otherwise call getobj.
    %1st loop to find the index or indices in the obj.Classes structure of
    %any methods of the input class.
    retrieved=false;
    index=0;
    for n=1:size(obj.Classes,2)
        %Does the nth entry in obj.Classes correspond to the input class
        %The 'any' statement here takes care of the possibility that
        %the obj.Classes entries are cell arrays of strings - ie if there
        %are alternative classes from the same package that can be used.
        
        %Note - the form of this statement means that if alternative
        %classes are listed in a method then they must be from the same
        %package.
        if any(strcmp(obj.Classes(n).classnames,methodName)) && strcmp(obj.Classes(n).packagenames,packageName)
            if size(index,2)==1
                index=n;
            else
                index(size(index,2+1))=1;
            end
        end
    end
    %If there is 1 index then retrieve the corresponding object (if its
    %ObjectNumber has been recorded.
    if size(index,2)==1%If there are >1 matching indices, need to use getobj and send parameters - this will happen below - leave retrieved==false.
        if index~=0
            if isfield(obj.Classes,'objectnumbers')
                if size(obj.Classes,2)>=index;%Check that there is an obj.Classes(index) entry
                    if ~isempty(obj.Classes(index).objectnumbers)
                        %If there are alternative classes then need to find
                        %the correct entry.
                        if size(obj.Classes(index).objectnumbers,2)>1
                            %obj.Classes(index) has several entries
                            match=strcmp(obj.Classes(index).classnames,methodname);
                            match=find(match);
                            if size(match,2)==1%Can only retrieve the object in this way if there is a single entry of the input class. Otherwise leave retrieved==false and use getobj below
                                methodObj=tl.methodFromNumber(obj.Classes(index).objectnumbers{match});
                            end                           
                        else%There is only a single class in this obj.Classes entry.
                        methodObj=tl.methodFromNumber(obj.Classes(index).objectnumbers);
                        end
                    end
                end
            end
            if exist('methodObj','var')%A method object has been retrieved
                retrieved=true;
            end
        end     
    end
    
    if ~retrieved
    %No object has been retrieved using the recorded object number - need to
    %call getobj to get the object.
        if nargin==5
            methodObj = tl.getobj(packageName,methodName);
        else
            methodObj = tl.getobj(packageName,methodName, varargin{:});
        end
        %Record in the classes property of obj that the calling method
        %(obj) uses the used method (methodObj)
        if isfield(obj.Classes,'objectnumbers')
            obj.Classes.objectnumbers(size(obj.Classes.objectnumbers,2)+1)=methodObj.ObjectNumber;
        else
            obj.Classes.objectnumbers=methodObj.ObjectNumber;
        end
        tl.setMethodObjField(obj.ObjectNumber, 'Classes', obj.Classes);
    end
    %Add the object to the fieldHistory
    fieldHistory(fieldIndex).methodobj=methodObj.ObjectNumber;
    fieldHistory(fieldIndex).levelobj=inputObj.ObjectNumber;
    %Populate the required fields (if any) for the method object. Any 
    %further method objects that are used by the methodObj.initializeFields
    %method will be recorded in the structure fieldHistory2.
    [inputObj fieldHistory2]=methodObj.initializeFields(inputObj);
    %merge fieldHistory2 with fieldHistory to create a complete
    %record of the method objects that have been used so far in
    %making this image.
    fieldHistory=methodObj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
    %Run methodObj. Any further method objects created during this run will
    %be recorded in the structure fieldHistory3.
    [inputObj fieldHistory3]= methodObj.run(inputObj);
    %Merge fieldHistory3 into fieldHistory to create a complete
    %record of the field history.
    fieldHistory=methodObj.addToFieldHistory(fieldHistory, fieldHistory3, fieldIndex);
end