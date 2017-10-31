function exportTrapImage(cTimelapse,export_directory,name,traps,timepoints,channels,do_TrapImage,do_SegmentationResult,cCellVision,do_DecisionImage)
% exportTrapImage(cTimelapse,export_directory,name,traps,channels,do_TrapImage,cCellVision,do_DecisionImage)
%
% function to export trap images as single images of same format as whole
% position images.
%
% fluorescent images are stored as uint16
% trap image as uint8. trap image times 128.
% decision image as a uint16. multiplied decision image by 100 and added
% 32768 (half of uintmax('uint16'))
% segmentation image as a uint16.
%
% WARNING if a cCellVision is provided the trapInfo of the cTimelapse WILL
% be overwritten so don't then save it.


if nargin<2 || isempty(export_directory)
    
    export_directory = uigetdir([],'please select a directory to which to export trap images');
    
end

if nargin<3 || isempty(name)
    name = 'exported_trap_images_';
end

if nargin<4 || isempty(traps)
    all_traps = true;
else
    all_traps = false;
end


if nargin<5 || isempty(timepoints)
    
    timepoints = 1:length(cTimelapse.cTimepoint);
    
end

if nargin<6 || isempty(channels)
    
    channels = cTimelapse.selectChannelGUI('channels to export','please select channels you wish to export trap images for:',true);
    
end

if nargin<7 || isempty(do_TrapImage)
    do_TrapImage = false;
end

if nargin<8 || isempty(do_SegmentationResult)
    do_SegmentationResult = false;
end

if nargin<9 || isempty(cCellVision)
    do_DecisionImage = false;
    use_trap_default = false;
else
    use_trap_default = true;
end

if nargin<10 || isempty(do_DecisionImage)
    do_DecisionImage = false;
end


fprintf('%d ',length(timepoints));
for tp = timepoints
    if all_traps
        traps = 1:length(cTimelapse.cTimepoint(tp).trapInfo);
    end
    for TIi = 1:length(traps)
            TI = traps(TIi);
            if ~isdir(sprintf('%s%strap%0.3d',export_directory,filesep,TI))
                mkdir(sprintf('%s%strap%0.3d',export_directory,filesep,TI));
            end
    end
    
    for chi = 1:length(channels)
        ch = channels(chi);
        image_stack = cTimelapse.returnTrapsTimepoint(traps,tp,ch);
        for TIi = 1:length(traps)
            TI = traps(TIi);
            
            image = uint16(image_stack(:,:,TIi));
            imwrite(image,sprintf('%s%strap%0.3d%s%s_trap%0.3d_tp%0.6d_%s.png',export_directory,filesep,TI,filesep,name,TI,tp,cTimelapse.channelNames{ch}));
            
        end
    end
    
    if do_TrapImage
        
        if use_trap_default
            default_trap = 1*cCellVision.cTrap.trapOutline;
        else
            default_trap = [];
        end
        
        traps_stack = returnTrapsPixelsTimepoint(cTimelapse,traps,tp,default_trap);
        for TIi = 1:length(traps)
            TI = traps(TIi);
            
            image = uint8(128*traps_stack(:,:,TIi));
            imwrite(image,sprintf('%s%strap%0.3d%s%s_trap%0.3d_tp%0.6d_TrapPixels.png',export_directory,filesep,TI,filesep,name,TI,tp));
            
        end
        
    end
    
    if do_SegmentationResult
        
        seg_res_stack = returnTrapsSegResTimepoint(cTimelapse,traps,tp);
        for TIi = 1:length(traps)
            TI = traps(TIi);
            
            image = uint16(seg_res_stack(:,:,TIi));
            imwrite(image,sprintf('%s%strap%0.3d%s%s_trap%0.3d_tp%0.6d_SegRes.png',export_directory,filesep,TI,filesep,name,TI,tp));
            
        end
        
    end
    
    if do_DecisionImage
        
        decision_image_stack = cTimelapse.generateSegmentationImages(tp,traps);
        for TIi = 1:length(traps)
            TI = traps(TIi);
            
            image = uint16(100*decision_image_stack(:,:,TIi) + 32768);
            imwrite(image,sprintf('%s%strap%0.3d%s%s_trap%0.3d_tp%0.6d_DIM.png',export_directory,filesep,TI,filesep,name,TI,tp));
            
        end
        
        
        
    end
    
    PrintReportString(tp,50);
end

fprintf('\n')

end


