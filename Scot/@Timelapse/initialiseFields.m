function obj=initialiseFields(obj,methodObj)
    % InitialiseFields --- Populates the timepoint fields required to run the input timepoint segmentation method
    %
    % Synopsis:  obj = InitialiseFields(obj, cellsegmethodobj, regionObj)   
    %                        
    % Input:     obj = an object of a Timepoint class
    %            methodObj = an object of a TimepointSegmethods class
    %
    % Output:    obj = an object of a Timepoint class

    % Notes:     Calculates images and other fields as required by the
    %            input method object. Uses the requiredFields property of
    %            timepointsegmethods class to determine the fields needed.
    %            Avoids unnecessary calculations by first checking if each
    %            field has already been created
        
    %loop through the required fields
    if size(methodObj.reqioredFields)>0
        for f=1:size(methodObj.requiredFields,1)
            switch char(methodObj.requiredFields(f))
                case 'EntropyFilt'
                    if isempty (obj.EntropyFilt)
                        obj.EntropyFilt=entropyFilt(obj.InputImage);
                    end
            end
        end
    end
end