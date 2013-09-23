classdef TimelapseSegMethodsSuperClass<MethodsSuperClass
    properties
      resultImage='Result';
    end
    methods (Abstract)
        [timelapseObj]=run(obj,timelapseObj);
    end
    methods (Static)
    end
end