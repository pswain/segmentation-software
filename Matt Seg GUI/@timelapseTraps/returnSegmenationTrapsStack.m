function [imagestack_out] = returnSegmenationTrapsStack(cTimelapse,traps,timepoint)
%[imagestack_out] = returnSegmenationStackTimpoint(cTimelapse,traps,timepoint)
%returns a cell array of image stacks defined by the property channelsForSegment to be
%used in the cell identification, so that each element of the cell array is
%an image stack for the corresponding trap in the traps vector

for ci = 1:length(cTimelapse.channelsForSegment)
    
    temp_im = cTimelapse.returnTrapsTimepoint(traps,timepoint,cTimelapse.channelsForSegment(ci));
    
    if ci==1
        
        imagestack_out = cell(length(traps),1);
        
        [imagestack_out{:}] = deal(zeros(size(temp_im,1),size(temp_im,2),length(cTimelapse.channelsForSegment)));
        
    end
    
    for ti=1:length(traps)
        
        imagestack_out{ti}(:,:,ci) = temp_im(:,:,ti);
        
    end
    
end

end