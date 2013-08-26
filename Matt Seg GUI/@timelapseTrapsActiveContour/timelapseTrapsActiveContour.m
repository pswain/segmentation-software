classdef timelapseTrapsActiveContour<handle
    %TIMELASPETRAPSACTIVECONTOUR Summary of this class goes here
    %   Detailed explanation goes here
    
    
    %This should be a class to hold active contour relevant data and
    %perform active contour segmentation of matt's trap data. Suggestions
    %of things to store are:
    
    %parameter for segmentation method
    %parameters structure
    %trap parameter structure
    %trap image
    %trap pixel image
    %trap locations as a sparse matrix

    %also a generic method for finding traps
    
    properties
        
        Parameters %structure of parameters for trap detection and segmentation
        TrapPresentBoolean = false;%boolean value to indicate if there are traps in the image
        TrapImage =[]; %DIC image of an empty trap
        TrapPixelImage=[]; %grayscale image of trappiness
        TrapGridImage = [];%image of field of view with no traps
        TrapLocation = []; %location of traps in timecourse
        TimelapseTraps = []; %Object of the TimelapseTraps class
        
    end
    
    methods
        
        function ttacObject= timelapseTrapsActiveContour(in)
            %constructor. Doesn't do anything really. Needs an input for
            %some reason.
            
           ttacObject.Parameters = struct('TrapDetection',struct,'ImageTransformation',struct,'ImageSegmentation',struct);
           ttacObject.TrapImage = [];
           ttacObject.TrapPixelImage = [];
           ttacObject.TrapLocation = [];
           
        end
        
    end
    
end

