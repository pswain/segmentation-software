function CellRes_draw_cell( CellResGUI )
% CellRes_draw_cell( CellResGUI ) draws the cell image in the image box.

trap_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);

cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

timepoint = CellResGUI.TimepointSelected;

image_channel_number = get(CellResGUI.SelectImageChannelButton,'Value');

cell_image = CellResGUI.cExperiment.cTimelapse.returnSingleTrapTimepoint(trap_number,timepoint,image_channel_number);

empty_outline = false(size(cell_image));
cell_outline = empty_outline;
curr_daughter_outline = empty_outline;
other_daughter_outlines = empty_outline;
other_cell_outlines = empty_outline;

trap_info = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number);
mother_label = [];
curr_daughter = [];
other_daughters = [];

%mother stuff
if ~isempty(CellResGUI.cExperiment.lineageInfo)
    mother_info = CellResGUI.cExperiment.lineageInfo.motherInfo;
    if ~isempty(mother_info.motherPosNum)
        %check if the selected cell is a mother cell
        mother_index = ismember([mother_info.motherPosNum' mother_info.motherTrap' mother_info.motherLabel'], ...
            CellResGUI.CellsForSelection(CellResGUI.CellSelected,:), 'rows');
        if any(mother_index)
            %This is a mother, so set the mother label
            mother_label = cell_tracking_number;
            %Update labels for daughters
            
            % preferentially use manual info.
            if isfield(mother_info,'daughterLabelManual') && ...
                    ~isempty(mother_info.daughterLabelManual)
                daughter_labels = mother_info.daughterLabelManual(mother_index,:);
                birth_times = mother_info.birthTimeManual(mother_index,:);
            else
                daughter_labels = mother_info.daughterLabelHMM(mother_index,:);
                birth_times = mother_info.birthTimeHMM(mother_index,:);
            end
            daughter_labels = daughter_labels(daughter_labels~=0);
            birth_times = birth_times(birth_times~=0);
            % Find the most recent birth time event
            recentBirth = find((birth_times(end:-1:1)-timepoint-1)<0,1);
            if isempty(recentBirth)
                % There is no current daughter yet
                other_daughters = daughter_labels;
            else
                curr_daughter_filter = (length(birth_times):-1:1)==recentBirth;
                curr_daughter = daughter_labels(curr_daughter_filter);
                other_daughters = daughter_labels(~curr_daughter_filter);
            end
        end
    end
end

for icell=1:length(trap_info.cellLabel)
    ilabel = trap_info.cellLabel(icell);
    if ~isequal(ilabel,0) && CellResGUI.ShowcellOutline
        seg_outline = full(trap_info.cell(icell).segmented);
        if ismember(ilabel,mother_label) || ilabel == cell_tracking_number
            cell_outline = seg_outline;
        elseif ismember(ilabel,curr_daughter)
            curr_daughter_outline = seg_outline;
        elseif ismember(ilabel,other_daughters)
            other_daughter_outlines = other_daughter_outlines | seg_outline;
        else
            other_cell_outlines = other_cell_outlines | seg_outline;
        end
    end
end

alpha_scaling = 0.8;
dim_scaling = 0.6;
im = alpha_scaling*(cell_image-CellResGUI.ImageRange(1))/diff(CellResGUI.ImageRange);
red_highlight = im;
red_highlight(cell_outline) = 1;
red_highlight(other_daughter_outlines) = dim_scaling*red_highlight(other_daughter_outlines);
green_highlight = im; 
green_highlight(curr_daughter_outline) = 1;
green_highlight(other_daughter_outlines) = dim_scaling;
blue_highlight = im; 
blue_highlight(other_cell_outlines) = 1;
blue_highlight(other_daughter_outlines) = dim_scaling*blue_highlight(other_daughter_outlines);
show_image = cat(3,red_highlight,green_highlight,blue_highlight);

if ~isempty(CellResGUI.cellImageSize)
    
    cTimelapse_cell_number = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cellLabel == cell_tracking_number;
    
    if sum(cTimelapse_cell_number==1)
    cell_centre = CellResGUI.cExperiment.cTimelapse.cTimepoint(timepoint).trapInfo(trap_number).cell(cTimelapse_cell_number).cellCenter;
    
    show_image = GetSubStack( show_image,[cell_centre(2) cell_centre(1) 2],[CellResGUI.cellImageSize 3]);
    show_image = show_image{1};
    end
end

% this slightly convoluted set of functions passes preserves the
% ButtonDownFunction and passes it to the image.
fun = CellResGUI.CellImageHandle.ButtonDownFcn;
I = imshow(show_image,'Parent',CellResGUI.CellImageHandle);
set(CellResGUI.CellImageHandle,'ButtonDownFcn',fun);
set(I,'ButtonDownFcn',fun);
set(I,'HitTest','on'); 
drawnow
end

