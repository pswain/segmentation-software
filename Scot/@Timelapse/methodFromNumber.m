function method=methodFromNumber(obj, number)
    % methodFromNumber ---  returns the method object saved in obj.ObjectStruct having the input ObjectNumber
    %
    % Synopsis:        method = methodFromNumber(obj, number)
    %
    % Input:           obj = and object of a Timelapse class.
    %                  number = integer, ObjectNumber of the required method object.
    %
    % Output:          method = an object of a method class (subclass of MethodsSuperClass)
    
    % Notes:           This function makes use of or creates the field
    %                  ObjectStruct.numbers, which provides a fast
    %                  reference for subsequent calls to this function.
    
    %initialize variable to determine if a method has been found
    found=false;
    %If the numbers field does not exist, loop through the packages and
    %classes to create it - this is the slow part - but should only happen
    %once
    if ~isfield(obj.ObjectStruct,'numbers')
        packages=fields(obj.ObjectStruct);
        count=1;
        for p = 1:size(packages,1)%loop through packages
            classes=fields(obj.ObjectStruct.(packages{p}));%List of method classes for which objects exist in this package
            if ~isempty(classes)
                for n=1:size(classes,1)%Loop through method object types in this package
                    class=classes{n};%Class of current objects
                    for m=1:size(obj.ObjectStruct.(packages{p}),2)%Loop through objects of this class
                        if ~isempty(obj.ObjectStruct.(packages{p})(m).(class))
                            obj.ObjectStruct.numbers.objnumber(count)=obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber;
                            obj.ObjectStruct.numbers.packagenames{count}=packages{p};
                            obj.ObjectStruct.numbers.classnames{count}=class;
                            obj.ObjectStruct.numbers.indices(count)=m;
                            count=count+1;
                            %Define the output method if the object
                            %considered here has the input number
                            if obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber==number                        
                                method=obj.ObjectStruct.(packages{p})(m).(class);
                                found=true;
                            end
                        end

                    end
                end
            end
        end
    else
        %The numbers field already exists - use it to retrieve the required
        %object
        index=obj.ObjectStruct.numbers.objnumber==number;
        if any(index)
            class=obj.ObjectStruct.numbers.classnames{index};
            package=obj.ObjectStruct.numbers.packagenames{index};
            num=obj.ObjectStruct.numbers.indices(index);
            method=obj.ObjectStruct.(package)(num).(class);
            found=true;
        end        
    end
    
    %If no method has been found then the required method has not yet been
    %added to the .numbers field (or doesn't exist)
    %Loop through the packages to find it and add to numbers field if found
    if ~found    
        packages=fields(obj.ObjectStruct);
        for p = 1:size(packages,1)%loop through packages
            classes=fields(obj.ObjectStruct.(packages{p}));%List of method classes for which objects exist in this package
            if ~isempty(classes)
                for n=1:size(classes,1)%Loop through method object types in this package
                    class=classes{n};%Class of current objects
                    for m=1:size(obj.ObjectStruct.(packages{p}),2)%Loop through objects of this class
                        if ~isempty(obj.ObjectStruct.(packages{p})(m).(class))
                            if ~strcmp(packages{p},'numbers')
                                if obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber==number                        
                                        method=obj.ObjectStruct.(packages{p})(m).(class);
                                        count=size(obj.ObjectStruct.numbers.objnumber,2)+1;
                                        obj.ObjectStruct.numbers.objnumber(count)=obj.ObjectStruct.(packages{p})(m).(class).ObjectNumber;
                                        obj.ObjectStruct.numbers.packagenames{count}=packages{p};
                                        obj.ObjectStruct.numbers.classnames{count}=class;
                                        obj.ObjectStruct.numbers.indices(count)=m;                                                        
                                        found=true;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if ~found
        method=[];
    end
    
end