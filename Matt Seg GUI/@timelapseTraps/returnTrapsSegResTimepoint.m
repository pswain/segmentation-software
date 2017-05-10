function seg_res_stack=returnTrapsSegResTimepoint(cTimelapse,traps,timepoint)
% seg_res_stack = returnTrapsSegResTimepoint(cTimelapse,traps,timepoint)
%
% returns a z-stack of the segmentation result of the timelapse, with
% pixels numbered according to which cell they belong to. In case of
% overlap the pixel is assigned to the last cell to 'own' it.
%
% also assumes cells have been tracked and fails otherwise.

if  isempty(traps)
    traps = 1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
end

disk = strel('disk',1);
seg_res_stack = zeros([2*cTimelapse.cTrapSize.bb_height+1 2*cTimelapse.cTrapSize.bb_width+1 length(traps)]);

if ~isempty(cTimelapse.cTimepoint(timepoint).trapInfo) 
for k=1:length(traps)
    trap = traps(k);
        if cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent
            trapInfo = cTimelapse.cTimepoint(timepoint).trapInfo(trap);
            cell_labels = zeros([2*cTimelapse.cTrapSize.bb_height+1 2*cTimelapse.cTrapSize.bb_width+1]);
            for ci = 1:length(trapInfo.cell)
                %cell_labels(imdilate(full(trapInfo.cell(ci).segmented),disk)) = trapInfo.cellLabel(ci);
                cell_labels(full(trapInfo.cell(ci).segmented)) = trapInfo.cellLabel(ci);
            
            end
            seg_res_stack(:,:,k) = cell_labels;
        end
        
end
end


end