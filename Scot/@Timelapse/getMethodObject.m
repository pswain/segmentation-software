function returnObject=getMethodObject(obj, type, frame, trackingnumber)
    % getMethodObject --- returns the first method object of the input type that was used in segmenting the cell with the input frame and tracking number.
    %
    % Synopsis:  returnObject = getMethodObject (obj, type, frame, trackingnumber)
    %
    % Input:     obj = an object of a timepoint class
    %            type = string, name of the package of the
    %            requested method object (eg cellsegmethods, timelapsesegmethods)
    %            frame = integer, the frame at which the queried cell was segmented
    %            trackingnumber = tracking number of the queried cell
    %                                               
    % Output:    returnObject = an object of a class belonging to the package 'type'

    % Notes:     This method is used to get the method object that
    %            was used to segment a given cell, region or timepoint.
    for n=1:size(obj.TrackingData(frame).cells(trackingnumber).methodobj,2)
        methodNo=obj.TrackingData(frame).cells(trackingnumber).methodobj(n);
        method=obj.methodFromNumber(methodNo);
        objectInfo=metaclass(method);
        if ~isempty(objectInfo.ContainingPackage)
            if strcmp(objectInfo.ContainingPackage.Name, type)==1
                returnObject=method;
                break;
            end
        end
        
    end
end