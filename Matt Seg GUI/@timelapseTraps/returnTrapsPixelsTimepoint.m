function trapsStack=returnTrapsPixelsTimepoint(cTimelapse,traps,timepoint,default_result)
%trapsStack=returnTrapsPixelsTimepoint(cTimelapse,traps,timepoint,default_result)
%
% returns a z-stack of the trap pixel images (i.e.images in which the
% pixels are scored according to their liklihood to be a trap pixel.
% Conventionally this is between 0 and 1 with 1 for certain. If the
% refineTrapOutline has been used then the result of this is returned,
% If this has not been used then an array populated with the default_result
% is used. This defaults to empty.

if isempty(traps)
    traps = 1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
end

if nargin<4||isempty(default_result)
    default_result = zeros([2*cTimelapse.cTrapSize.bb_height+1 2*cTimelapse.cTrapSize.bb_width+1]);
end

trapsStack = zeros([2*cTimelapse.cTrapSize.bb_height+1 2*cTimelapse.cTrapSize.bb_width+1 length(traps)]);



% if cTimelapse.refinedTrapOutline has been run then use this for trap
% outline.
for k=1:length(traps)
    if cTimelapse.trapsPresent
        if isfield(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)),'refinedTrapPixelsInner') &&...
                ~isempty(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)).refinedTrapPixelsInner) &&...
                isfield(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)),'refinedTrapPixelsBig') &&...
                ~isempty(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)).refinedTrapPixelsBig)
            
            trapsStack(:,:,k) = 0.5*full(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)).refinedTrapPixelsBig) +...
                0.5*full(cTimelapse.cTimepoint(timepoint).trapInfo(traps(k)).refinedTrapPixelsInner);
        
        else
            trapsStack(:,:,k) = default_result;
        end
    end
end


end