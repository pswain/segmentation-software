function obj=initialiseFields(obj,methodobj, timepointObj)
    % initialiseFields --- Populates the region fields required to run the input method
    %
    % Synopsis:  obj = InitialiseFields(regionObj, methodobj, timepointObj)   
    %                        
    % Input:     obj = an object of a region class
    %            methodobj = an object of a class that modifies a region object - eg a splitregion or regionsegmethod class
    %            timepointObj = an object of a timepoint class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     Calculates images and other fields as required by the
    %            input method object. Uses the requiredFields property of
    %            a method object to determine the fields needed. Avoids
    %            unnecessary calculations by first checking if each field
    %            has already been created.
        
    %loop through the required fields
    if size(methodobj.requiredFields,1)>0
        for f=1:size(methodobj.requiredFields,1)
            switch char(methodobj.requiredFields(f))
                case 'Bw'
                    if ~isfield (obj.RequiredImages,'Bw')
                        obj.getBw(timepointObj.Bin);
                    end
                case 'Watershed'
                    if ~isfield (obj.RequiredImages,'Watershed')
                        if ~isfield (obj.RequiredImages,'Bw')
                            obj.getBw(timepointObj.Bin);
                        end
                        obj=timepointObj.Timelapse.ObjectStruct.runmethods.RunSplitRegionMethod.run(obj, timepointObj);
                    end
                case 'Target'
                    if ~isfield (obj.RequiredImages,'Target')
                        obj.Target=timepointObj.InputImage(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
                    end
            end
        end
    end
end