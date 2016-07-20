classdef FlowInTrapTrained < ACMotionPriorObjects.FlowInTrap
    %FLOWINTRAPTRAINED same as FlowInTrap but movements are trained on
    %data.
    
    properties
    end
    
    methods
        function self = FlowInTrapTrained(cTimelapse, cCellVision)

            self = self@ACMotionPriorObjects.FlowInTrap(cTimelapse,cCellVision);
            
            % load files from training mat file.
            trained_arrays_file_location = mfilename('fullpath');
            FileSepLocation = regexp(trained_arrays_file_location,filesep);
            trained_arrays_file_location = fullfile(trained_arrays_file_location(1:FileSepLocation(end)),'FlowInTrapTrained_array.mat');
            l1 = load(trained_arrays_file_location);
            self.flowLookUpTable = l1.flowLookUpTable;
            self.sizeLookUpTable = l1.sizeLookUpTable;
        end
        
        
    end
    
end

