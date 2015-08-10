function fieldValue=getMethodObjField(obj, objectNumber, field)
    % getMethodObjField ---  %Returns the value of a field in a method object saved in timelapse.ObjectStruct
    %
    % Synopsis:        obj = setMethodObjField (obj, objectNumber, field, value)
    %
    % Input:           obj = an object of a Timelapse class.
    %                  objectNumber = integer, ObjectNumber of the required method object
    %                  value = any type, the value of the field to be modified
    %
    % Output:          fieldValue = the content of the requested field
    % 
    
    % Notes:
    packages=fields(obj.ObjectStruct);
    for p = 1:size(packages,1)%loop through packages
        classes=fields(obj.ObjectStruct.(packages{p}));%List of method classes for which objects exist in this package        
        for n=1:size(classes,1)%Loop through method object types in this package            
            class=classes{n};%Class of current objects
            for m=1:size(obj.ObjectStruct.(packages{p}),2)%Loop through objects of this class
                if~isempty(obj.ObjectStruct.(packages{p})(m).(class))
                    if obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber==objectNumber
                        if isempty(obj.ObjectStruct.(packages{p})(m).(class).Info)
                            obj.ObjectStruct.(packages{p})(m).(class).Info=metaclass(obj.ObjectStruct.(packages{p})(m).(class).Info);
                        end
                        props=obj.ObjectStruct.(packages{p})(m).(class).Info.Properties;
                        for o=1:size(props,1)
                            %Is this the requested property?
                            if strcmp(props{o}.Name,field)
                                fieldValue=obj.ObjectStruct.(packages{p})(m).(class).(field);
                            end
                        end
                        if ~exist('fieldValue','var')
                            fieldValue=[];
                        end                        
                    end
                end
            end
        end
    end   
end