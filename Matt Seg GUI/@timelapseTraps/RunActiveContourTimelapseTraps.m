function RunActiveContourTimelapseTraps( cTimelapse,FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,ACmethod,CellsToUse )
%RUNACTIVECONTOURTIMELAPSE( cTimelapse,FirstTimepoint,LastTimepoint )
%basically a straightforward way to run the active contour methods
%developed by me (Elco) on the cTimelapse object. 


if isempty(cTimelapse.ActiveContourObject)
    fprintf('\nPlease instanstiate the active contour object first by running the instantiateActiveContourTimelapseTraps methods first. If there are traps in this timelapse you will also have to fillout the trap locations in one way or another.\n')
    return
elseif cTimelapse.ActiveContourObject.TrapPresentBoolean && isempty(cTimelapse.ActiveContourObject.TrapLocation)
    fprintf('\nIf traps are present in the timelapse you need to provide trap locations before running the active contour method\n')
    return
end

if nargin <3 || (isempty(FirstTimepoint) || isempty(LastTimepoint))
    answer = inputdlg(...
        {'Enter the timepoint at which to begin the active contour method' ;'Enter the timepoint at which to stop'},...
        'start and end times of active contour method',...
        1,...
        {'1'; int2str(length(cTimelapse.cTimepoint))});
    
    FirstTimepoint = str2num(answer{1});
    LastTimepoint = str2num(answer{2});
end

if nargin<4 || isempty(LeaveFirstTimepointUnchanged)
    LeaveFirstTimepointUnchanged = false;
end

if (nargin<5 || isempty(ACmethod))
    [ACmethod,method_dialog_answer_value] = cTimelapse.ActiveContourObject.SelectACMethod;
else
    [ACmethod,method_dialog_answer_value] = cTimelapse.ActiveContourObject.SelectACMethod(ACmethod);
end

if method_dialog_answer_value == false;
    fprintf('\n\n   Active contour method cancelled\n\n')
    return
end

if nargin<6 || isempty(CellsToUse)
    CellsToUse = [];
end


cTimelapse.ActiveContourObject.RunActiveContourMethod(FirstTimepoint,LastTimepoint,LeaveFirstTimepointUnchanged,ACmethod,CellsToUse)

fprintf('finished running active contour methods on timelapse \n')
end
