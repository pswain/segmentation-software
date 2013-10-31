classdef TrapFindingMethods<MethodsSuperClass
    properties
        requiredFields
    end
    methods (Abstract)
        [timepointObj]=run(obj,timepointObj);
        timepointObj=initializeFields(obj, timepointObj);
    end
    methods (Static)
    end
end