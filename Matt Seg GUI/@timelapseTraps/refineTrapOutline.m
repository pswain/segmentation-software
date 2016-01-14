function refineTrapOutline(cTimelapse,starting_trap_outline,channels,traps,timepoints)
% refineTrapOutline(cTimelapse,starting_trap_outline,channel,traps,timepoints)
%
% calculate a refined trap outline by simple thresholding and store it in
% trapInfo of each trap and each timepoint.
%
% cTimelapse                :   timelapseTraps object
% traps                     :   (optional)array of trap Indices for which to refine
%                               trap outline
% timepoints                :   (optional)timepoints at which to refine trap outline.
% starting_trap_outline     :   logical of where the traps are likely to
%                               be.
% channels                  :   image channel to use. Can be array with
%                               positive and negative entries for adding or
%                               subtracting channels
%
% performs refinement by seperating the image into those regions above the
% median and finding the connected regions that most overlap with the
% starting_trap_outline (most often taken from cCellVision). stores the
% result in cTimelapse.cTimepoint.trapInfo.refinedTrapPixels.
%
% the result is only the inner region, and should probably be dilated by
% about 4 or 5 to give the best guess of the trap pixels 

if nargin<3 || isempty(channels)
    channels =  selectChannelGUI(cTimelapse,'Trap Refine Channel',...
        'please select a channel with which to refine the trap outline. Traps are expected to be bright with a dark halo.',...
        false);
end

if nargin<4 || isempty(traps)
    traps = cTimelapse.defaultTrapIndices;
end

if nargin<5 || isempty(timepoints)
    timepoints = cTimelapse.timepointsToProcess;   
end

%% get labelled trap
dilation_length =4;
strel_1 = strel('disk',dilation_length);
f= figure;

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


%% get image
im = [];

wh = waitbar(0,'refininf trap outline');
for tp = timepoints
    if nargin<4
        
        traps = 1:length(cTimelapse.cTimepoint(tp).trapInfo);
        
    end
    for chi = 1:length(channels)
        
        temp_im = cTimelapse.returnTrapsTimepoint(traps,tp,abs(channels(chi)));
        temp_im = temp_im - median(temp_im(:));
        temp_im = temp_im*sign(channels(chi));
        if chi>1
            im = im + temp_im;
        else
            im = temp_im;
        end
    end
    
    %% process
    
    
    for ti = 1:length(traps)
        %im_thresh = im(:,:,ti)>(median(im(:))/10);
    
        trap = traps(ti);
        temp_im = im(:,:,ti);
        medVal = median(temp_im(:));
        temp_im = temp_im - medVal;
        trap_im_orig = temp_im>-medVal;
        
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
            
            final_trap_pixels = final_trap_pixels | feature_pixels;
            
        end
        
        final_trap_pixels_big = imdilate(final_trap_pixels,strel_1);
        final_trap_pixels_big = final_trap_pixels | (~trap_im_orig & final_trap_pixels_big);
        final_trap_pixels_big = imfill(final_trap_pixels_big,'holes');
        
        if sum(final_trap_pixels_big(:))==numel(final_trap_pixels)
            fprintf('debug');
        end
        
        
        cTimelapse.cTimepoint(tp).trapInfo(trap).refinedTrapPixelsInner = sparse(final_trap_pixels);
        cTimelapse.cTimepoint(tp).trapInfo(trap).refinedTrapPixelsBig = sparse(final_trap_pixels_big);
        
        %for inspection
        if false
            figure(f);imshow(OverlapGreyRed(im(:,:,ti),final_trap_pixels,false,final_trap_pixels_big,true),[]);
            pause(0.3);
        end
    end
    
waitbar(tp/max(timepoints(:)),wh);
end
close(f);


end