function [ imagestack_out ] = processSegmentationTrapStack( cTimelapse,image_stack,traps,timepoint,type )
%[ imagestack_out ] = processSegmentationTrapStack( cTimelapse,imagestack,traps,timepoint,type )
%
% Processing function for returnSegmentationTrapStack. Allows loading and
% processing to be separated for speed in certain functions.
%
% cTimelapse    :   object of the timelapseTraps class
% traps         :   Array of of indices of traps for which segmentation
%                   image stack should be returned.
% timepoint     :   timepoint from which to return images
% type          :   optional. String determining which sort of image to
%                   return. Written to match the cCellVision.method field
%                   and generally taken from the
%                   cCellVision.imageProcessMethod field.
%                   default is 'twostage'
%                   'twostage' or 'linear' : return a cell array with each element
%                                            being an image stack for
%                                            the trap in the traps array provided, with
%                                            each slice of each stack being a given
%                                            channel.
%                   wholeIm      : return a single element cell array
%                                  containing stack of whole
%                                  timepoint image . Each slice is the whole
%                                  image at a given channel
%                   wholeTrap  : return a single element cell array
%                                containing stack of trap images laid in a
%                                long strip. Each slice is a strip of trap
%                                images at a given channel.
%                   twostage_norm   : as twostage by subtracts the median
%                                     of each channel and divides by the
%                                     interquartile range.
%                   'twostage_norm_fluor'  : as two stage but subtracts the
%                                            median and then divides by the
%                                            mean of the pixels above 3*the
%                                            75th percentile (attempt to
%                                            rule out background pixels and
%                                            normalised just fluorescent
%                                            ones).
%
% imagestack_out : cell array of image stacks with the exact content being
%                  determined by 'type' input as described above.
%
if nargin<5
    type = 'twostage';
end

if ~cTimelapse.trapsPresent
    type = 'wholeIm';
end



for ci = 1:size(image_stack,3)
    if ismember(type,{'twostage','linear','trap','twostage_norm','twostage_norm_fluor'}) %trap option is for legacy reasons
        % return a cell array with each element being an image stack for
        % the trap in the traps array provided
        temp_im = image_stack(:,:,ci);
        if ismember(type,{'twostage_norm'})
            temp_im = temp_im - median(temp_im(:));
            prctile_range = prctile(temp_im(:),[2 98]);
            % using this percentile range was arbitrarily chosen to try and
            % get a range defined by the trap pixels that would be somewhat
            % robust to hot pixels. Seemed to work well even for crowded
            % images.
            temp_im = temp_im./(prctile_range(2) - prctile_range(1));
        end
        if ismember(type,{'twostage_norm_fluor'})
            % heuristic normalisation for fluorescent images intended to
            % return them to a similar range whatever the brightness. Idea
            % is that the median is always background (not too many cells)
            % and that the upper 10 percent a fluorescent cells - so
            % normalising to the standard deviation of the cells.
            prcentiles = prctile(temp_im(:),[50, 90]);
            s_upper = std(temp_im(temp_im>prcentiles(2)));
            temp_im = (temp_im-prcentiles(1))/s_upper;
            
            
        end
        mval=1.3*mean(temp_im(:));
        temp_stack = cTimelapse.returnTrapsFromImage(temp_im,timepoint,traps);
        if ci==1
            imagestack_out = cell(length(traps),1);
            [imagestack_out{:}] = deal(mval*ones(size(temp_stack,1),size(temp_stack,2),size(image_stack,3)));
        end
        for ti=1:length(traps)
            imagestack_out{ti}(:,:,ci) = temp_stack(:,:,ti);
        end
    elseif ismember(type,{'wholeIm','whole'}) %'whole' is for legacy reasons
        % return a single element cell array containing stack of whole
        % timepoint image
        % each slice is a channel
        temp_im = image_stack(:,:,ci);
        mval=mean(temp_im(:));
        if ci==1
            imagestack_out = cell(1,1);
            imagestack_out{1} = mval*ones(size(temp_im,1),size(temp_im,2),length(cTimelapse.channelsForSegment));
        end
        imagestack_out{1}(:,:,ci) = temp_im;
    elseif strcmp(type,'wholeTrap') 
        % return a single element cell array containing stack of trap images laid in a long strip
        % each slice is a channel
        temp_im = image_stack(:,:,ci);
        mval=mean(temp_im(:));
        temp_stack = cTimelapse.returnTrapsFromImage(temp_im,timepoint,traps);
        
        
        if ci==1
            imagestack_out = cell(1,1);
            colL=size(temp_stack,2);
            imagestack_out{1} = mval*ones(size(temp_stack,1),size(temp_stack,2)*length(traps),length(cTimelapse.channelsForSegment));
        end
        for ti=1:length(traps)
            imagestack_out{1}(:,1+(ti-1)*colL:ti*colL,ci) = temp_stack(:,:,ti);
        end
    end 
end

end

