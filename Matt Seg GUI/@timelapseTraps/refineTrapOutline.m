function refineTrapOutline(cTimelapse,starting_trap_outline,traps,timepoints,show_output)
% refineTrapOutline(cTimelapse,starting_trap_outline,channels,traps,timepoints,show_output,do_close)
%
% calculate a refined trap outline by simple thresholding and store it in
% trapInfo of each trap and each timepoint.
%
% cTimelapse                :   timelapseTraps object
% starting_trap_outline     :   logical of where the traps are likely to
%                               be.
% traps                     :   (optional)array of trap Indices for which to refine
%                               trap outline
% timepoints                :   (optional)timepoints at which to refine trap outline.
%
% performs refinement using the trap refine function and parameters
% specified in:
%           cTimelapse.ACParams.TrapDetection 
% and a provided starting_trap_outline (most often taken from cCellVision).
% stores the result in cTimelapse.cTimepoint.trapInfo.refinedTrapPixels.

if cTimelapse.trapsPresent


if nargin<3 || isempty(traps)
    traps = cTimelapse.defaultTrapIndices;
    all_traps = true;
end

if nargin<4 || isempty(timepoints)
    timepoints = cTimelapse.timepointsToProcess;   
end

if nargin<5 || isempty(show_output)
    show_output = false;
end


TrapRefineChannel = cTimelapse.ACParams.TrapDetection.channel;

TrapRefineFunction =  str2func(['ACTrapFunctions.' cTimelapse.ACParams.TrapDetection.function]);
TrapRefineParameters = cTimelapse.ACParams.TrapDetection.functionParams;

TrapRefineParameters.starting_trap_outline = starting_trap_outline;
TrapRefineFunction = @(stack) TrapRefineFunction(stack,TrapRefineParameters);

        


if show_output
    f= figure;
end


wh = waitbar(0,'refininf trap outline');
for tp = timepoints
    
    
    TrapRefineImage = 0;
    
    for chi = 1:length(TrapRefineChannel)
        channel = abs(TrapRefineChannel(chi));
        TempIm = double(cTimelapse.returnSingleTimepoint(tp,channel));
        
        TrapRefineImage = TrapRefineImage + sign(TrapRefineChannel(channel==abs(TrapRefineChannel))) * TempIm;
    end
    
   
    if all_traps
        
        traps = 1:length(cTimelapse.cTimepoint(tp).trapInfo);
        
    end
    
    TrapImageStack = cTimelapse.returnTrapsFromImage(TrapRefineImage,tp,traps);
    TrapTrapImageStack = TrapRefineFunction(TrapImageStack);
    
    %% write result
    
    
    for ti = 1:length(traps)
        %im_thresh = im(:,:,ti)>(median(im(:))/10);
        trap = traps(ti);
       
        cTimelapse.cTimepoint(tp).trapInfo(trap).refinedTrapPixelsInner = sparse(TrapTrapImageStack(:,:,ti)>=1);
        cTimelapse.cTimepoint(tp).trapInfo(trap).refinedTrapPixelsBig = sparse(TrapTrapImageStack(:,:,ti)>=0.5);
        
        %for inspection
        if show_output
            figure(f);imshow(OverlapGreyRed(TrapImageStack(:,:,ti),TrapTrapImageStack(:,:,ti)>=1,false,TrapTrapImageStack(:,:,ti)>=0.5,true),[]);
            pause(0.1);
        end
    end
    
waitbar(tp/max(timepoints(:)),wh);
end
if show_output
    close(f);
end
close(wh);


end
end