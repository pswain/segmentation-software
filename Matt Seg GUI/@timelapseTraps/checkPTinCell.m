function [ cell_index ] = checkPTinCell( cTimelapse,TP,TI,locations_to_check )
% [ cell_index ] = checkPTinCell(% cTimelapse,timepoint,trap,locations_to_check ) 
% checks if points are within a cell outline. locations_to_check given in
% matrix notation [I,J] where I is the vertically down, 1st, axis and J is
% the horizontal, 2nd, axis. currently only handles 1 point.

cell_index = [];

if any(locations_to_check > cTimelapse.trapImSize) || any(locations_to_check<1)
    return
end

locations_to_check = sub2ind(cTimelapse.trapImSize,locations_to_check(:,1),locations_to_check(:,2));
n = 1;
trapInfo = cTimelapse.cTimepoint(TP).trapInfo(TI);

while isempty(cell_index) && n<= length(trapInfo.cell) && trapInfo.cellsPresent
    
    cell_outline = imfill(full(trapInfo.cell(n).segmented),'holes');
    if cell_outline(locations_to_check)
        cell_index = n;
        break
    end
    
    n=n+1;
end

end

