function [inputObj fieldHistory] = useMethodClass(inputObj, fieldHistory, fieldName, packageName, methodName, varargin)
    % useMethod --- Creates, initializes and runs an object of the input method class name and package
    %
    % Synopsis:  [inputObj fieldHistory] = useMethod(inputObj, fieldHistory, fieldName, packageName, methodName)  
    %            [inputObj fieldHistory] = useMethod(inputObj, fieldHistory, fieldName, packageName, methodName varargin)  
    %                        
    % Input:     inputObj = an object of a level class
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
    %Create or retrieve an object of the input  class
    if nargin==5
        methodObj = inputObj.getobj(packageName,methodName);
    else
        methodObj = inputObj.getobj(packageName,methodName, varargin{:});
    end
    %Add the object to the fieldHistory
    fieldHistory(fieldIndex).objects=methodObj.ObjectNumber;
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
    fieldHistory(fieldIndex)=regionFinder.addToFieldHistory(fieldHistory, fieldHistory3, fieldIndex);
end