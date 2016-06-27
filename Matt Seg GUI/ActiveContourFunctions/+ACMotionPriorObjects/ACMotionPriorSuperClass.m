classdef ACMotionPriorSuperClass
    %ACMOTIONPRIORSUPERCLASS Super class for objects that provide a motion
    %prior based on the position and size of the cell.
    %constructor is expected to receive parameters_structure and cellVision
    %object
    
    properties
    end
    
    methods
        
        
        
        function prior_array = returnPrior(self,cell_loc,cell_radius)
            
            fprintf('\n\n this should be written to an array representing where the cell is likely to move to given its properties (size and location)\n\n')
            
        end
    end
    
end

