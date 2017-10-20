function [DecisionImageStack, EdgeImageStack,TrapTrapImageStack,ACTrapImageStack,RawDecisionIms]...
    =generateSegmentationImages(cTimelapse,cCellVision,timepoint,traps_to_check,ACParams)
% [DecisionImageStack, EdgeImageStack,TrapTrapImageStack,ACImage,RawDecisionIms]...
%    = generateSegmentationImages(cTimelapse,cCellVision,timepoint,traps_to_check,ACParams)
%
% calculates a number of images used in the segmentation software.
%
% cTimelapse    :   object of the timelapseTraps class
% cCellVision   :   object of the cellVision class
% timepoint     :   timepoint at which the segmentation is occurring.
%                   defaults to 1.
% traps_to_check:   array of indices of traps at which segmentation should
%                   be performed. defaults to 1.
% ACParams      :   an active contour parameters structure. If not provided
%                   it will use cTimelapse.ACParams with any missing fields
%                   filled in from default. This line is there so that a
%                   structure can be passed and time consuming loads of the
%                   default parameter set avoided.
%
%
% OUTPUTS
% 
% DecisionImageStack    :   stack of images (one slice per trap) in which
%                           centres have a low score and all else a high one.
% EdgeImageStack        :   stack of images (one slice per trap) in which
%                           edges have a low score and all else a high one.
% TrapTrapImageStack    :   stack of images (one slice per trap) in which
%                           trap pixels have a high score (1).
% ACTrapImageStack      :   stack of images (one slice per trap)
%                           used in the active contour method. Signed sum
%                           of image channels specified in
%                           cTimelapse.ACparams.ImageTransform.channel
%                           normalised by gradient of trap pixels over whole image.
% RawDecisionIms        :   cell array of image stacks. Currently:
%                           RawDecisionIms{1} is the BG decision image
%                           (high scores for background pixels)
%                           RawDecisionIms{2} is the centre/edge decision image
%                           (high scores for edge pixels)


if nargin<3
    timepoint=1;
end

if nargin<4
    traps_to_check=1;
end

if nargin<5 || isempty(ACParams)
    % for any unspecified parameters use the default values.
    ACParams = parse_struct(cTimelapse.ACParams,timelapseTraps.LoadDefaultACParams);
end

ACImageChannel = ACParams.ImageTransformation.channel;

DecisionImageChannel = cTimelapse.channelsForSegment;

TrapPresentBoolean = cTimelapse.trapsPresent;

if TrapPresentBoolean
    TrapRefineChannel = ACParams.TrapDetection.channel;
    if isempty(TrapRefineChannel)
        TrapRefineChannel = cTimelapse.channelForTrapDetection;
    end
    TrapRefineFunction =  str2func(['ACTrapFunctions.' ACParams.TrapDetection.function]);
    TrapRefineParameters = ACParams.TrapDetection.functionParams;
    if isempty(TrapRefineParameters.starting_trap_outline);
        TrapRefineParameters.starting_trap_outline = cCellVision.cTrap.trapOutline;
    end
    TrapRefineFunction = @(stack) TrapRefineFunction(stack,TrapRefineParameters);
else
    TrapRefineChannel = [];
end


AllChannelsToLoad = unique(abs([ACImageChannel TrapRefineChannel DecisionImageChannel]));

%ensure images are only loaded once even if used in various parts of
%the code.
for chi = 1:length(AllChannelsToLoad)
    channel = AllChannelsToLoad(chi);
    TempIm = double(cTimelapse.returnSingleTimepoint(timepoint,channel));
    
    
    if chi==1
        %preallocate images for speed. DIMImage is stack rather than
        %single image.
        ACImage = zeros(size(TempIm));
        TrapRefineImage = ACImage;
        DIMImage = zeros([size(TempIm) length(DecisionImageChannel)]);
        
    end
    
    % sum images into a single 2D image
    if ismember(channel,abs(ACImageChannel))
        ACImage = ACImage + sign(ACImageChannel(channel==abs(ACImageChannel))) * TempIm;
    end
    
    % sum images into a single 2D image
    if TrapPresentBoolean &&    ismember(channel,abs(TrapRefineChannel))
        TrapRefineImage = TrapRefineImage + sign(TrapRefineChannel(channel==abs(TrapRefineChannel))) * TempIm;
    end
    
    % in this case images are stacked
    if ismember(channel,DecisionImageChannel)
        DIMImage(:,:,channel==DecisionImageChannel) = TempIm;
    end
end

ACImage = IMnormalise(ACImage);

if TrapPresentBoolean
    %for holding trap images of trap pixels.
    DefaultTrapOutline = 1*cCellVision.cTrap.trapOutline;
    TrapTrapImageStack = cTimelapse.returnTrapsFromImage(TrapRefineImage,timepoint,traps_to_check);
    TrapTrapImageStack = TrapRefineFunction(TrapTrapImageStack);
    
    % since this WholeTrapImage (a logical of all traps in the image)
    % is used for normalisation we don't want to use only the traps
    % being checked. So fill in unchecked traps with default outline
    % from cCellVision.
    DefaultTrapIndices = cTimelapse.defaultTrapIndices(timepoint);
    DefaultTrapImageStack = repmat(DefaultTrapOutline,[1,1,length(DefaultTrapIndices)]);
    for trapi = 1:length(traps_to_check)
        trap = traps_to_check(trapi);
        DefaultTrapImageStack(:,:,trap) = TrapTrapImageStack(:,:,trapi);
    end
    WholeTrapImage = cTimelapse.returnWholeTrapImage(DefaultTrapImageStack,timepoint,DefaultTrapIndices);
else
    TrapTrapImageStack = zeros([size(DIMImage,1), size(DIMImage,2),length(traps_to_check)]);
    WholeTrapImage = zeros([size(DIMImage,1), size(DIMImage,2)]);
end

% normalise AC image by gradient at traps
% seemed to produce the most consistent behaviour.
TrapMask = WholeTrapImage>0;
if any(TrapMask(:))
    [ACImageGradX,ACImageGradY] = gradient(ACImage);
    ACImage = ACImage/mean(sqrt(ACImageGradX(TrapMask).^2 + ACImageGradY(TrapMask).^2  ));
end

% make ACImage into trap image stack
ACTrapImageStack = cTimelapse.returnTrapsFromImage(ACImage,timepoint,traps_to_check);
    
% this calculates the decision image
% though methods exist in the cellVision class to do this more
% directly, it was pulled ou to avoid loading the image multiple
% times if they are used for both active contour and decision
% image.
[ SegmentationStackArray ] = processSegmentationTrapStack( cTimelapse,DIMImage,traps_to_check,timepoint,cCellVision.imageProcessingMethod);

DecisionImageStack = zeros(size(TrapTrapImageStack));
EdgeImageStack = DecisionImageStack;
RawBgDIM = DecisionImageStack;
RawCentreDIM = DecisionImageStack;
have_raw_dims = false(1,size(TrapTrapImageStack,3));
%fprintf('change back to parfor in DIM calculation\n')

if length(traps_to_check)>1
    current_pool = gcp;
    pool_size = current_pool.NumWorkers;
else
    pool_size = 0;
end
parfor (k=1:length(traps_to_check),pool_size)
    [~, d_im_temp,~,raw_dims]=cCellVision.classifyImage2Stage(SegmentationStackArray{k},TrapTrapImageStack(:,:,k));
    DecisionImageStack(:,:,k)=d_im_temp(:,:,1);
    if size(d_im_temp,3)>1
        % Matt at some point started returning a second slice for
        % the decision image that was an edge probability. This
        % code doesn't use that, but I keep it here to be robust
        % against it.
        EdgeImageStack(:,:,k)=d_im_temp(:,:,2);
    end
    if ~isempty(raw_dims)
        have_raw_dims(k) = true;
        RawBgDIM(:,:,k) = raw_dims(:,:,1);
        RawCentreDIM(:,:,k) = raw_dims(:,:,2);
    end
end

if all(have_raw_dims);
    RawDecisionIms = {RawBgDIM,RawCentreDIM};
else
    RawDecisionIms = {};
end
end

function WholeImage = IMnormalise(WholeImage)

WholeImage = double(WholeImage);
WholeImage = WholeImage - median(WholeImage(:));
IQ = iqr(WholeImage(:));
if IQ>0
    WholeImage = WholeImage./iqr(WholeImage(:));
end

end