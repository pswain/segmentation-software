function [imagestack_out] = returnSegmenationTrapsStack(cTimelapse,traps,timepoint,type)
%[imagestack_out] = returnSegmenationTrapsStack(cTimelapse,traps,timepoint,type) 
%
% returns a cell array of image stacks defined by the property
% channelsForSegment of cTimelapse to be used in the cell identification.
% In any case each slice of the image stack corresponds to a channel given
% in the array stored in the property channelsForSegment of cTimelapse.
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
% processing of this function is done by 
%    timelapseTraps.processSegmentationTrapStack 
% this allows separation of processing and loading for speed. 


if nargin<4
    type = 'twostage';
    if ~cTimelapse.trapsPresent
        type = 'wholeIm';
    end
end



image_stack = [];

for ci = cTimelapse.channelsForSegment
    image_stack = cat(3,image_stack,cTimelapse.returnSingleTimepoint(timepoint,ci));
end

[ imagestack_out ] = processSegmentationTrapStack( cTimelapse,image_stack,traps,timepoint,type );
 

end