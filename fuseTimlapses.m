function cTimelapseOUT = fuseTimlapses(timelapse_cell)
%function cTimelapseOUT = fuseTimlapses(timelapse_cell)  a function to fuse
%a cell vector of timelapses by making their paths absolute and then
%concatenating their cTimepoints vectos. 

%only the cTimepoint, timepointsProcessed and timepointsToProcess will
%be preserved.

%labels, offsets, background
%corrections and all that will be all messed up. Not a big problem since it
%is designed for making big cTimelapses for CellVision training but worth
%worrying about if using fluorescent image sets with different offsets for
%example.




if ~isempty(timelapse_cell)
   
    for tli = 1:length(timelapse_cell)
        
        current_timelapse = timelapse_cell{tli};
        if tli ==1
            
            current_timelapse.makeFileNamesAbsolute;
            cTimelapseOUT = current_timelapse.copy;
            
        else
%             if isfield(current_timelapse.cTimepoint,'trapMaxCell')
%                 current_timelapse.cTimepoint=rmfield(current_timelapse.cTimepoint,'trapMaxCell');
%             end
            
            current_timelapse.makeFileNamesAbsolute;
            cTimelapseOUT.timepointsProcessed = [cTimelapseOUT.timepointsProcessed (current_timelapse.timepointsProcessed+length(cTimelapseOUT.cTimepoint))];
            cTimelapseOUT.timepointsToProcess = [cTimelapseOUT.timepointsToProcess  (current_timelapse.timepointsToProcess +length(cTimelapseOUT.cTimepoint))];
            cTimelapseOUT.cTimepoint = [cTimelapseOUT.cTimepoint(1:end) current_timelapse.cTimepoint(1:end)];
%             cTimelapseOUT.cTimepoint(end+1:end+length(current_timelapse.cTimepoint))=current_timelapse.cTimepoint(1:end);

        end
    end
    
end

end