function [ refined_trap_stack ] = forPhaseContrast( stack,params )
% [ refined_trap_stack ] = simpleThreshold( stack,params )
% 
% performs refinement by seperating the image into those regions above the
% median and within a dilated starting trap outline (for each feature
% individually). Imfills these to get the pillars.
% if difference between starting outline and found trap outline is more
% than 30% of startingtrap outline, throws is away and keeps starting trap
% outline.
%
% params:
%   dilate_length           :   see description
%   starting_trap_outline   :   see description
%   do_close                :   whether to do an image processing close on the final
%                               pixel outline

starting_trap_outline = params.starting_trap_outline;
do_close = params.do_close;
dilation_length = params.dilate_length;


refined_trap_stack = zeros(size(stack));

%% get labelled trap
strel_1 = strel('disk',dilation_length);

labelled_start_trap = bwlabel(starting_trap_outline);
unique_start_trap = unique(labelled_start_trap(:));
unique_start_trap(unique_start_trap==0) = [];


% no features so done
if isempty(unique_start_trap);
    return
end

labelled_start_trap_stack = false([size(labelled_start_trap) length(unique_start_trap)]);
labelled_start_trap_stack_dilated = labelled_start_trap_stack;
for li = 1:length(unique_start_trap)
    temp_im = false(size(labelled_start_trap));
    temp_im(labelled_start_trap==unique_start_trap(li)) = true;
    labelled_start_trap_stack(:,:,li) = temp_im;
    labelled_start_trap_stack_dilated(:,:,li) = imdilate(temp_im,strel_1);
    
end



%% process


for ti = 1:size(stack,3)
    
    temp_im = stack(:,:,ti);
    medVal = median(temp_im(:));
    temp_im = temp_im > medVal;
    
    final_trap_pixels = false(size(temp_im));
    final_trap_pixels_big = final_trap_pixels;
    
    for li = 1:length(unique_start_trap)
        
        feature_start_pixels = labelled_start_trap_stack(:,:,li);
        feature_start_pixels_dilated = labelled_start_trap_stack_dilated(:,:,li);
        
        feature_pixels = (temp_im & feature_start_pixels_dilated)|feature_start_pixels;
        feature_pixels = imopen(feature_pixels,strel_1);
        feature_pixels = imfill(feature_pixels,'holes');
        
        if sum(feature_pixels(:) & ~feature_start_pixels_dilated(:))>(0.3 * sum(feature_start_pixels_dilated(:)))
            feature_pixels = feature_start_pixels_dilated;
        end
        
        if do_close
            feature_pixels = imclose(feature_pixels,strel_1);
        end
        
        final_trap_pixels_big = final_trap_pixels_big | feature_pixels;
        final_trap_pixels = final_trap_pixels | imerode(feature_pixels,strel_1);
        
    end
    
    
    final_im = zeros(size(temp_im));
    final_im(final_trap_pixels_big) = 0.5;
    final_im(final_trap_pixels) = 1;
    refined_trap_stack(:,:,ti) = final_im;

end


end

