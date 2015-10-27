classdef EditTimelapse<MethodsSuperClass
    properties
        resultImage='Result'
    end
    methods
        [timepointObj]=run(obj,timepointObj);
        timepointObj=initializeFields(obj, timepointObj);
    end
end