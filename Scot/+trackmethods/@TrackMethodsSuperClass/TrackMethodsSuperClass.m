classdef TrackMethodsSuperClass <MethodsSuperClass
    %superclass for trackmethod classes.
    properties
       resultImage='Result';
    end
    methods (Abstract)
         Timelapse =run(TrackMethod,Timelapse) 
             %abstract method to indicate every Track method function needs a run method
    end
end
