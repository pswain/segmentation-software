function [ refined_trap_stack ] = simpleThreshold( stack,params )
% [ refined_trap_stack ] = simpleThreshold( stack,params )
% 
% performs refinement by seperating the image into those regions above the
% median and finding the connected regions that most overlap with the
% starting_trap_outline (most often taken from cCellVision). These pixels
% are set to 1 in refined_trap_stack. Pixels within params.dilate_length of
% these which are below the median are set to 0.5.
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
%for enlarging large trap outline.
strel_2 = strel('disk',ceil(dilation_length/4));


dilated_start_trap_im = imdilate(starting_trap_outline,strel_1);

labelled_start_trap = bwlabel(starting_trap_outline);
unique_start_trap = unique(labelled_start_trap(:));
unique_start_trap(unique_start_trap==0) = [];


% no features so done
if isempty(unique_start_trap);
    return
end

labelled_start_trap_stack = false([size(labelled_start_trap) length(unique_start_trap)]);
for li = 1:length(unique_start_trap)
    temp_im = false(size(labelled_start_trap));
    temp_im(labelled_start_trap==unique_start_trap(li)) = true;
    labelled_start_trap_stack(:,:,li) = temp_im;
    
end



%% process


parfor ti = 1:size(stack,3)
    
    temp_im = stack(:,:,ti);
    medVal = median(temp_im(:));
    temp_im = temp_im - medVal;
    trap_im_orig = temp_im>prctile(temp_im(:),25);
    
    trap_im = trap_im_orig;
    trap_im(~dilated_start_trap_im) = false;
    trap_label_im = bwlabel(trap_im);
    
    final_trap_pixels = false(size(trap_im));
    for li = 1:length(unique_start_trap)
        
        feature_start_pixels = labelled_start_trap_stack(:,:,li);
        
        trap_feature_pixels = trap_label_im(feature_start_pixels);
        trap_feature_pixels(trap_feature_pixels==0) = NaN;
        feature_label = mode(trap_feature_pixels);
        
        feature_pixels = trap_label_im==feature_label;
        feature_pixels = imdilate(feature_pixels,strel_1);
        feature_pixels = imfill(feature_pixels,'holes');
        feature_pixels = imerode(feature_pixels,strel_1);
        
        if sum(feature_pixels(:))<0.5 * sum(feature_start_pixels(:))
            feature_pixels = feature_start_pixels;
        end
        
        if do_close
            feature_pixels = imclose(feature_pixels,strel_1);
        end
        
        final_trap_pixels = final_trap_pixels | feature_pixels;
        
    end
    
    final_trap_pixels_big = imdilate(final_trap_pixels,strel_1);
    final_trap_pixels_big = final_trap_pixels | (~trap_im_orig & final_trap_pixels_big);
    final_trap_pixels_big = imfill(final_trap_pixels_big,'holes');
    final_trap_pixels_big = imdilate(final_trap_pixels_big,strel_2);

    final_im = zeros(size(temp_im));
    final_im(final_trap_pixels_big) = 0.5;
    final_im(final_trap_pixels) = 1;
    refined_trap_stack(:,:,ti) = final_im;

end


end

