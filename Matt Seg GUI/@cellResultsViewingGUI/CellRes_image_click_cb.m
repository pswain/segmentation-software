function CellRes_image_click_cb(CellResGUI,src,event)
% CellRes_image_click_cb(CellResGUI,src,event)
%
% callback for clicking on the cell image. Currently has two modes:
% left click (mouse button 1)   -  adds a birth event at the current time
%       point of the GUI and tries to find the daughter cell to which it
%       applies. To do this it looks for a cell under the click in any of
%       the 5 timepoints following. If a cell is found, this cell is added
%       to the birth event. If not, the daughter label NaN is used.
%
% right click (mouse button >1) -  removes the nearest birth even in time
%       with no consideration of the location of the click. 
%
% NOTE: the time of the birth event is set by the current time of the GUI.
% This has a number of properties.
% 1- a birth event can be separated from the point at which cell is born.
%    so can be before OR AFTER the cell is found by the software.
% 2- can have no cell attached if none was found by the software.
% 3- the same cell (according to the software) can be assigned to numerous
%    birth events. This is useful if the cell was incorrectly tracked.
%
% See also, EXPERIMENTTRACKING.EDITBIRTHMANUAL

% number of timesteps forward to look for a new budding even at that point.
tps_to_look_forward = 5;

TP = CellResGUI.TimepointSelected;
loc = round(event.IntersectionPoint(1:2));

cell_position = CellResGUI.CellsForSelection(CellResGUI.CellSelected,1);
trap_index = CellResGUI.CellsForSelection(CellResGUI.CellSelected,2);
cell_tracking_number = CellResGUI.CellsForSelection(CellResGUI.CellSelected,3);

%left click
if event.Button==1
    cell_index = [];
    n = -1;
    % look a few timesteps into the future to try and identify the
    % daughter.
    while isempty(cell_index) && n<=tps_to_look_forward
        n = n+1; 
        cell_index = CellResGUI.cExperiment.cTimelapse.checkPTinCell(...
            TP+n,...
            trap_index,...
            fliplr(loc) );
    end
    % if cell_index is empty (n cell could be found under the click),
    % this will return and empty value which will result in a NaN in
    % the daughter label
    cell_label = CellResGUI.cExperiment.cTimelapse.cTimepoint(TP+n).trapInfo(trap_index).cellLabel(cell_index);
    editBirthManual( CellResGUI.cExperiment,'+', TP,cell_position,trap_index,cell_tracking_number,cell_label );
    CellResGUI.needToSave = true;

    
    %right click - made it greater than 1 because I wasn't sure it would always
    %be 3 (what it is on mine)
elseif event.Button>1
    editBirthManual( CellResGUI.cExperiment,'-', TP,cell_position,trap_index,cell_tracking_number );
end

CellResGUI.CellRes_draw_cell;
CellResGUI.CellRes_plot;
end

