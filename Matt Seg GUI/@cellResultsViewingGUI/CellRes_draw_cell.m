function CellRes_draw_cell( CellResGUI )
% CellRes_draw_cell( CellResGUI ) draws the cell image in the image box.

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

cell_number = find(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number);

image_channel_number = get(CellResGUI.SelectImageChannelButton,'Value');

cell_image = CellResGUI.cExperiment.cTimelapse.returnSingleTrapTimepoint(trap_number,timepoint,image_channel_number);

if ~isempty(cell_number) && CellResGUI.ShowcellOutline
    cell_outline = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cell(cell_number).segmented;
else
    cell_outline = false([CellResGUI.cExperiment.cTimelapse.cTrapSize.bb_width CellResGUI.cExperiment.cTimelapse.cTrapSize.bb_height]*2 + 1);
end


%mother stuff
if ~isempty(CellResGUI.cExperiment.lineageInfo)
    mother_info = CellResGUI.cExperiment.lineageInfo.motherInfo;
    %check if it is a mother cell
    if ~isempty(mother_info.motherPosNum)
        mother_index = ismember([mother_info.motherPosNum' mother_info.motherTrap' mother_info.motherLabel'], ...
            CellResGUI.CellsForSelection(CellResGUI.CellSelected,:), ...
            'rows');
    else
        mother_index = [];
    end
else
    mother_index = [];
end

if any(mother_index)
    daughter_cell_numbers = find(ismember(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel, ...
        mother_info.daughterLabelHMM(mother_index,:)) & ~(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel==0));
    daughter_outlines = false(size(cell_outline));
    for di = daughter_cell_numbers
        daughter_outlines = daughter_outlines | full(CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cell(di).segmented);
    end
    
else
    daughter_outlines = false(size(cell_outline));
    
end

show_image = OverlapGreyRed(double(cell_image),cell_outline,[],daughter_outlines,true,true,CellResGUI.ImageRange);

if ~isempty(CellResGUI.cellImageSize)
    
    cTimelapse_cell_number = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number;
    
    if sum(cTimelapse_cell_number==1)
    %GetSubStack( Stack,Centres,SizeOfSubStack)
    cell_centre = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cell(cTimelapse_cell_number).cellCenter;
    
    show_image = GetSubStack( show_image,[cell_centre(2) cell_centre(1) 2],[CellResGUI.cellImageSize 3]);
    show_image = show_image{1};
    end
end

imshow(show_image,'Parent',CellResGUI.CellImageHandle);

end

