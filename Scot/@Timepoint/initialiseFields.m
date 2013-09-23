function obj=initialiseFields(obj,methodobj)
    % InitialiseFields --- Populates the timepoint object fields required to run the input timepoint segmentation method
    %
    % Synopsis:  obj = InitialiseFields(obj, methodobj)   
    %                        
    % Input:     obj = an object of a Timepoint class
    %            methodobj = an object of a timepointsegmethod class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     Calculates images and other fields as required by the
    %            input method object. Uses the requiredFields property of
    %            timpointsegmethod class to determine the fields needed.
    %            Avoids unnecessary calculations by first checking if each
    %            field has already been created
        
    %loop through the required fields
    if size(methodobj.requiredFields,1)>0
        for f=1:size(methodobj.requiredFields,1)
            switch char(methodobj.requiredFields(f))
                case 'ThreshTarget'
                    switch methodobj.parameters.targetimage
                        case('EntropyFilt')
                            obj.ThreshTarget=entropyfilt(obj.InputImage);
                    end
            end
                    
        end
    end
end