function max_cell_label = returnMaxCellLabel(cTimelapse,trap,timepoint_range)
% max_cell_num = getMaxCellNum(cTimelapse,trap,timepoint_range)
%
% intended to replace trapMaxCell, which is ever problematic. returns the
% maximum cell label occurring in the timepoints timepoint_range. defaults
% to cTimelapse.timepointsToProcess.

if nargin<3 || isempty(timepoint_range)
    
    timepoint_range = cTimelapse.timepointsToProcess;
    
end

tic;
max_cell_label = [];
for tp = timepoint_range
    
    max_cell_label = max([cTimelapse.cTimepoint(tp).trapInfo(trap).cellLabel max_cell_label]);
    
end
toc