function timepointIm=returnSingleTimepoint(cTimelapse,timepoint,channel,type)
% timepointIm=returnSingleTimepoint(cTimelapse,timepoint,channel,type)
%
% Returns the image for a particular channel at a particular timepoint,
% applying some corrections defined by TIMELAPSETRAPS properties.
% 
% timepoint   :   number indicating the desired timepoint (will access this
%                 element of the cTimepoint array).
% channel     :   number (default 1) indicating which of the channels in
%                 cTimelapse.channelNames to return.
%
% type        :   string (default 'max'). if more than one file is loaded
%                 (e.g. in the case of a z stack) how to handle this stack.
%                 either 'max','sum','min' or 'stack' - applying
%                 concomitant operation to the stack or returning the whole
%                 stack in the case of 'stack'. This is done after the
%                 image is converted to a double.
%
% Loads the image (or images in the case of a 'stack' channel) from file
% using the RETURNSINGLETIMEPOINTRAW method, which returns a stack of
% images.
%
% This stack is then treated accoding to the 'type' argument, with
% either a projection ('min','max' etc.) being made or the whole stack
% being returned ('stack'). The default is max.
% A number of operations are then applied to the image in the following
% order.
%
% background correction - if the field cTimelapse.BackgroundCorrection{channel}
%                         is not empty it is taken to be a flat field
%                         correction and is appplied to the image by
%                         element wise multiplication.
%                         if BackgroundOffset is also populated then this
%                         is first subtracted, then added back after the
%                         flat field mutliplication. This was found to
%                         prevent the flat field correction increasing the
%                         noisy camera background in the case of low image
%                         values.
%
%
% scaling - if the timelapseTraps.imSize is different from
%           timelapseTraps.rawImSize (these are generally set when traps
%           are selected based on the pixelSize properties of
%           timelapseTraps and cellVision) then the raw image is resized to
%           imSize using imresize. This may cause a loss of resolution.
%
% rotation - if cTimelapse.image_rotation is not zero the image is rotated
%            by this amount (in degrees) using imrotate function. Any extra
%            elements added are padded with the mean value of the image.
%            This will change the size of the image if the angle is not a
%            multiple of 90.
%
% offset - if the channel row of the array cTimelapse.offset is not zero
%          then the image is shifted by this amount (offset is specified as
%          [x_offset y_offset]). Allows images from different channels to
%          be registered properly. Any extra values are padded by the
%          mean value of the image.
%
% These corrections are applied in this order.
%
% If there is no filename matching the channel at the timepoint requested
% an image of the appropriate size of all zeros is returned and a warning
% displayed.
%
% If the channel has been loaded into memory
% (TIMELAPSETRAPS.LOADCHANNELINTOMEMORY) then no image is loaded and this
% image, which will already have been corrected, is used instead.
%
% See also TIMELAPSETRAPS.RETURNSINGLETIMEPOINTRAW, TIMELAPSETRAPS.LOADCHANNELINTOMEMORY

if nargin<3 || isempty(channel)
    channel=1;
end

if nargin<4 || isempty(type)
    type='max';
end

% if the correct channel has been preloaded, use this image.
if isfield(cTimelapse.temporaryImageStorage,'channel') && channel == cTimelapse.temporaryImageStorage.channel
    timepointIm = cTimelapse.temporaryImageStorage.images(:,:,timepoint);
    timepointIm = double(timepointIm);
    return
end


timepointIm = returnSingleTimepointRaw(cTimelapse,timepoint,channel);

%necessary for background correction and just makes life easier
timepointIm = double(timepointIm);

%change if want things other than maximum projection
switch type
    case 'min'
        timepointIm=min(timepointIm,[],3);
    case 'max'
        timepointIm=max(timepointIm,[],3);
    case 'stack'
    case 'sum'
        timepointIm=sum(timepointIm,3);
end


%used for padding data
medVal=mean(timepointIm(:));

stack_depth = size(timepointIm,3);

% apply background correction. 
% This should really be called 'flat field correction', since it .multiplies
% the image. If backgroundOffset is not empty for this channel, this is
% first subtracted, the image is then .multiplied by BackgroundCorrection,
% and backgroundOffset is then added back. This is to preserve
% combarability with images where the background is not subtracted. 
if isprop(cTimelapse,'BackgroundCorrection') && size(cTimelapse.BackgroundCorrection,2)>=channel && ~isempty(cTimelapse.BackgroundCorrection{channel})
    bgdScaling = cTimelapse.BackgroundCorrection{channel}(:,:,ones(size(timepointIm,3),1));
    if isprop(cTimelapse,'BackgroundOffset') && length(cTimelapse.BackgroundOffset)>=channel && ~isempty(cTimelapse.BackgroundOffset{channel})
        bgdOffset = cTimelapse.BackgroundOffset{channel};
        timepointIm = bgdOffset + (timepointIm - bgdOffset).*bgdScaling;
    else
        timepointIm = timepointIm.*bgdScaling;
    end
end



% if scaledImSize (the size of the final image before rotation) and
% rawImSize (the size of the loaded image) are different, then rescale
if  any(cTimelapse.scaledImSize ~= cTimelapse.rawImSize)
    new_im = zeros([cTimelapse.scaledImSize stack_depth]);
    for si = 1:stack_depth
        new_im(:,:,si) = imresize(timepointIm,cTimelapse.scaledImSize);
    end
    timepointIm = new_im;
    clear new_im
end



% rotate image. It is first padded to try and prevent zeros occuring in the
% final image as an artefact of the padding.
if cTimelapse.image_rotation~=0
    bbN = ceil(0.5*max(cTimelapse.scaledImSize)); tIm=[];
    for slicei = 1:stack_depth;
        tpImtemp = padarray(timepointIm(:,:,slicei),[bbN bbN],medVal,'both');
        tpImtemp = imrotate(tpImtemp,cTimelapse.image_rotation,'bilinear','loose');
        tIm(:,:,slicei) = tpImtemp(bbN+1:end-bbN,bbN+1:end-bbN);
        if slicei==1 && stack_depth>1
            tIm(:,:,2:stack_depth) = 0;
        end
    end
    timepointIm = tIm;
    clear tIm
    clear tpImtemp
end

% shift image by 'offset' to make is align with other channels.
if isprop(cTimelapse,'offset') && size(cTimelapse.offset,1)>=channel && any(cTimelapse.offset(channel,:)~=0)
    boundaries = fliplr(cTimelapse.offset(channel,:));
    lower_boundaries = abs(boundaries) + boundaries +1;
    upper_boundaries = [size(timepointIm,1) size(timepointIm,2)] + boundaries + abs(boundaries);
    timepointIm = padarray(timepointIm,[abs(boundaries) 0],medVal);
    timepointIm = timepointIm(lower_boundaries(1):upper_boundaries(1),lower_boundaries(2):upper_boundaries(2),:);
end

% populate this if 
if isempty(cTimelapse.imSize)
    cTimelapse.imSize = [size(timepointIm,1),size(timepointIm,2)];
end

end