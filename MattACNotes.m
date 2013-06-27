%NOTES On MATT CODE INTEGRATION

%% GUI

%have editActiveContourTimelapseGUI, which is a hacked up version of Matt's
%cTrapDisplay GUI with the addremovecell replaced by chooseCellToEdit. Idea
%is that editActiveContourTimelapseGUI will work like Matt's, with the
%whole timelapse displayed, then selecting a cell will open a new GUI,
%which will also be a hack of Matts cTrapDisplay but which shows the active
%contour result for consecutive timepoints and lets you give new contours
%and check how the score change when you do.

%NEED TO:

%Write that second GUI
%Write CosFunctions so that they can spit out numerous components of cost
%function.


%notes on matt's code:

%for cellvisiontrainingGUI need to:
% load images and whatnot
% select traps with right click to make trap images
% set negative points to 1000 or so
% train first stage (only need second for linear)
% save timelapse and cellvision model.


%% BUG FIXES

%made a slight bug fix that was overwriting new trapinfo with blank trap
%info. It was in line 62 of cTimelapse.identifyCellCentersTrap. Probably
%not picked up by matt because it was for the linear cellvision model, and
%all hist are probably fancier than that.


%% cellVision addition
% 
% cell vision now has a field:
%  cCellVision.cTrap.contour 
% which is a binary image 0 everywhere but the
%  edge of the test traps (trap 1 and trap2). Could make it different for
%  every trap by replacing this field at each trap but also need to rerun
%  lines 33 - 46 of createImFilterSetCellTrap so probably not worth doing.

% To create a cellVision model put a trap contour in
% cCellVision.cTrap.contour (can just be trap outline in the same
% structure). then put a debug at line 48 of createImFilterSetCellTrap abd
% rerun the 'if' loop. May throw errors a few times but will eventually
% work.
