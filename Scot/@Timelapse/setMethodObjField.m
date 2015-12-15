function obj=setMethodObjField(obj, objectNumber, field, value,param)
    % setMethodObjField ---  %Alters a field in a method object saved in timelapse.ObjectStruct
    %
    % Synopsis:        obj = setMethodObjField (obj, objectNumber, field, value)
    %
    % Input:           obj = an object of a Timelapse class.
    %                  objectNumber = integer, ObjectNumber of the required method object
    %                  field = string, the name of the field to be modified
    %                  value = any type, the value of the field to be modified
    %                  param = logical, true if the field is in the methodObj.parameters structure, false or not input if not
    %
    % Output:          obj = an object of a timelapse class
    
    % Notes:
    if nargin<5
        param=false;
    end
    packages=fields(obj.ObjectStruct);
    for p = 1:size(packages,1)%loop through packages
        classes=fields(obj.ObjectStruct.(packages{p}));%List of method classes for which objects exist in this package
        for n=1:size(classes,1)%Loop through method object types in this package
            class=classes{n};%Class of current objects
            for m=1:size(obj.ObjectStruct.(packages{p}),2)%Loop through objects of this class
                if ~isempty(obj.ObjectStruct.(packages{p})(m).(class))
                    if ~strcmp(packages{p},'numbers')
                        if obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber==objectNumber
                            %Eval statement will deal with the situation in which
                            %there are dots or brackets in the input string, but
                            %may crash if the input string is nonsense. Would be
                            %good to rewrite this in a better way if problems
                            %arise.
                            %eval_str = ['obj.ObjectStruct.' packages{p} '.' class '(' num2str(m) ').' field '=value;'];
                            if param
                                eval_str = ['obj.ObjectStruct.' packages{p} '(' num2str(m) ').' class '.parameters.' field '=value;'];
                            else
                                eval_str = ['obj.ObjectStruct.' packages{p} '(' num2str(m) ').' class '.' field '=value;'];
                            end
                            eval(eval_str);
                        end
                    end
                end
            end
        end
    end   
end



