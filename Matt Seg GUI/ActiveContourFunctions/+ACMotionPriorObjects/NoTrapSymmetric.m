classdef NoTrapSymmetric < ACMotionPriorObjects.ACMotionPriorSuperClass
    %NOTRAPSYMMETRIC simply a symmetric jump radius of a known size given
    %by smoothing terms
    
    properties
        prior_array %the prior array that is returned when requested.
    end
    
    methods
        function self = NoTrapSymmetric(cCellVision,jump_terms)
            % self = NoTrapSymmetric(cCellVision,jump_terms)
            % just a jump prior of a fixed size (possibly modify in the
            % future to be more spread for smaller cells)
            prior_size = jump_terms(2);
            prior_array = zeros([prior_size, prior_size]);
            prior_array(ceil([prior_size, prior_size]/2)) = 1;
            smoothing_element = fspecial('gaussian',jump_terms(2)*[1 1],jump_terms(1));
            smoothing_element = smoothing_element/max(smoothing_element(:));
            self.prior_array = conv2(prior_array,smoothing_element,'same');
                
        end
        
        function prior_array = returnPrior(self,cell_loc,cell_radius)
           %prior_array = returnPrior(self,cell_loc,cell_radius)
           % just return self.prior_array
           
           prior_array = self.prior_array;
        end
    end
    
end

