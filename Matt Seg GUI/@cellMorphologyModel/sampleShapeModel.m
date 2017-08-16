function radii_array = sampleShapeModel( cCellMorph,initial_radii,time_points,show_images )
% radii_array = sampleShapeModel( cCellMorph,initial_radii,time_points,show_images )
%
% samples shape space based on trained shape model and shows the result.
%
% cCellMorph    -   cellMorphologyModel object that already has a shape
%                   model.
% initial_radii -   Radii of cell at first timepoint. If not provided, 
%                   will be sample.
% time_points   -   number of timepoints to sample (including the first)
% show_images   -   boolean. Whether to show the images of the sampled
%                   cells or not.
if nargin<2 || isempty(initial_radii)
    initial_radii = sample_first_cell(cCellMorph);
end


if nargin<3 || isempty(time_points)
    time_points = 5;
end


if nargin<4 || isempty(show_images)
    show_images = true;
    
end

radii_array = zeros(time_points,length(initial_radii));
radii_array(1,:) = initial_radii;

for tp = 2:time_points
    previous_radii = ACBackGroundFunctions.reorder_radii(radii_array(tp-1,:));
    radii_array(tp,:) = sample_tracked_cell(cCellMorph,previous_radii);
end

if show_images
    imsize = [1,1]*4*ceil(max(radii_array(:)))+1;
    imcentre = [1,1]*2*ceil(max(radii_array(:)))+1;
    temp_im_old = false(imsize);
    for tp = 1:time_points
        subplot(1,time_points,tp);
        temp_im = ACBackGroundFunctions.get_outline_from_radii(...
            radii_array(tp,:),cCellMorph.angles,imcentre,imsize);
        imshow(temp_im_old+2*temp_im,[0,4]);
        temp_im_old = temp_im;
        
    end
    
end

end

function initial_radii = sample_first_cell(cCellMorph)

    initial_radii = mvnrnd(cCellMorph.mean_new_cell_model,cCellMorph.cov_new_cell_model);

end

function next_radii = sample_tracked_cell(cCellMorph,previous_radii)
    if mean(previous_radii)<=cCellMorph.thresh_tracked_cell_model
        radii_ratio = mvnrnd(cCellMorph.mean_tracked_cell_model_small,...
            cCellMorph.cov_tracked_cell_model_small);
    else
        radii_ratio = mvnrnd(cCellMorph.mean_tracked_cell_model_large,...
            cCellMorph.cov_tracked_cell_model_large);
    end

    next_radii = previous_radii.*exp(radii_ratio);
    
end