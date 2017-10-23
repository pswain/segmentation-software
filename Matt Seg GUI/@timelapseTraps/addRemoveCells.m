function addRemoveCells(cTimelapse,cCellVision,cCellMorph,timepoint,trap,selection,pt)
% addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt)
%
% cTimelapse        :   object of the timelapseTraps class
% cCellVision       :   object of the cellVision class
% timepoint         :   the timepoint at which a cell should be added or
%                       removed
% trap              :   index of the trap from which a cell should be added
%                       or removed
% selection         :   string. a type of selection -
%                       add,remove,addPlot or removePlot
% pt                :   the point 'clicked' in [x y] format.

% if selection is 'remove', the cell with its centre nearest to pt is
% identified and removed from the
% cTimelapse.cTimepoint(timpoint).trapInfo(trap) 
% If selection is 'add' a cell is added using the TIMELAPSETRAPS.ADDCELL
% method.
% See also, TIMELAPSETRAPS.ADDCELL, TIMELAPSETRAPS.REMOVECELL

switch selection
    case 'add'
        cTimelapse.addCell(cCellVision,cCellMorph,timepoint,trap,round(pt));
    case 'remove'
        
        cell_to_remove_index = cTimelapse.ReturnNearestCellCentre(timepoint,trap,pt);
        cTimelapse.removeCell(timepoint,trap,cell_to_remove_index);

end

end