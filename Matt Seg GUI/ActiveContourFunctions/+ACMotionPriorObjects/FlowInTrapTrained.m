classdef FlowInTrapTrained < ACMotionPriorObjects.FlowInTrap
    %FLOWINTRAPTRAINED same as FlowInTrap but movements are trained on
    %data.
    
    properties
    end
    
    methods
        function self = FlowInTrapTrained(cTimelapse, cCellVision,smoothing_terms)
            % self = FlowInTrapTrained(cTimelapse, cCellVision,smoothing_terms)
            % smoothing terms are terms in a smoothing gaussian [std size]  
            
            self = self@ACMotionPriorObjects.FlowInTrap(cTimelapse,cCellVision);
            smoothing_element = fspecial('gaussian',smoothing_terms(2)*[1 1],smoothing_terms(1));
            smoothing_element = smoothing_element/max(smoothing_element(:));
            % load files from training mat file.
            trained_arrays_file_location = mfilename('fullpath');
            FileSepLocation = regexp(trained_arrays_file_location,filesep);
            trained_arrays_file_location = fullfile(trained_arrays_file_location(1:FileSepLocation(end)),'FlowInTrapTrained_array.mat');
            l1 = load(trained_arrays_file_location);
            flow_look_up = l1.flowLookUpTable;
            
            for i = 1:size(flow_look_up,3)
                temp_im = flow_look_up(:,:,i);
                temp_im = conv2(temp_im,smoothing_element,'same');
                flow_look_up(:,:,i) = temp_im;
            end
            
            self.flowLookUpTable = flow_look_up;
            size_look_up = l1.sizeLookUpTable;
            
            for i = 1:size(size_look_up,3)
                temp_im = size_look_up(:,:,i);
                temp_im = conv2(temp_im,smoothing_element,'same');
                size_look_up(:,:,i) = temp_im;
            end
            
            self.sizeLookUpTable = size_look_up;
        end
        
        
    end
    
end

