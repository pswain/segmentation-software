function [DecisionImageStack, EdgeImageStack]=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,traps_to_check,varargin)
% d_im=identifyCellCentersTrap(cTimelapse,cCellVision,timepoint,traps_to_check)
%
% calculates a number of images used in the segmentation software for
% inspection and use in other parts of the code.
%
% cTimelapse    :   object of the timelapseTraps class
% cCellVision   :   object of the cellVision class
% timepoint     :   timepoint at which the segmentation is occurring.
%                   defaults to 1.
% traps_to_check:   array of indices of traps at which segmentation should
%                   be performed. defaults to 1.                 
%
% cut and pasted first section of segmentACexperimental code. Probably not
% very good practice but there you go.

if nargin<3
    timepoint=1;
end

if nargin<4
    traps_to_check=1;
end
    
DecisionImageChannel = cTimelapse.channelsForSegment;

TrapPresentBoolean = cTimelapse.trapsPresent;

if TrapPresentBoolean
    TrapRefineChannel = cTimelapse.ACParams.TrapDetection.channel;
    if isempty(TrapRefineChannel)
        TrapRefineChannel = cTimelapse.channelForTrapDetection;
    end
    TrapRefineFunction =  str2func(['ACTrapFunctions.' cTimelapse.ACParams.TrapDetection.function]);
    TrapRefineParameters = cTimelapse.ACParams.TrapDetection.functionParams;
    if isempty(TrapRefineParameters.starting_trap_outline);
        TrapRefineParameters.starting_trap_outline = cCellVision.cTrap.trapOutline;
    end
    TrapRefineFunction = @(stack) TrapRefineFunction(stack,TrapRefineParameters);
else
    TrapRefineChannel = [];
end


AllChannelsToLoad = unique(abs([TrapRefineChannel DecisionImageChannel]));
    
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
    if TrapPresentBoolean &&    ismember(channel,abs(TrapRefineChannel))
        TrapRefineImage = TrapRefineImage + sign(TrapRefineChannel(channel==abs(TrapRefineChannel))) * TempIm;
    end
    
    % in this case images are stacked
    if ismember(channel,DecisionImageChannel)
        DIMImage(:,:,channel==DecisionImageChannel) = TempIm;
    end
end

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

else
    TrapTrapImageStack = zeros([size(DIMImage,1), size(DIMImage,2),length(traps_to_check)]);
end

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
parfor k=1:length(traps_to_check)
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


end




