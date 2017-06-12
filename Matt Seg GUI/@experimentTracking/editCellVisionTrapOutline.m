function editCellVisionTrapOutline( cExperiment,pos,TP,channel,poses)
% editCellVisionTrapOutline( cExperiment,pos,TP,channel ) 
% changes the trap image and outline of cCellVision attached to the
% cExperiment file to be mopre representative for the current experiment.
% 
% pos       -   the position that will be used for the example trap. If not
%               specified it is chosen randomly
% TP        -   the timepoint that will be used for the example trap. If not
%               specified it is chosen randomly
% channel   -   the channel to use for trapDetection. If not specified, is
%               chosen by GUI. The channelForTrapDetection field of all
%               timelapses will also be set to this channel for
%               consistency.
%
% Then applies CELLVISION.IDENTIFYTRAPOUTLINE with an example trap from the
% cTimelapse.
% 
% following this, trap1 and trap2 are modified so that the pixel values
% outside the trapOutline feature mask will not contribute to the cross
% correlation when looking for trap features. This help the software to
% distinguish cells and trap.
%
% See also EXPERIMENTTRACKING.EDITCELLVISIONTRAPOUTLINE ,
% CELLVISION.IDENTIFYTRAPOUTLINE, TIMELAPSETRAPS.IDENTIFYTRAPLOCATIONSSINGLETP

if nargin<2 || isempty(pos)
    pos = randperm(length(cExperiment.dirs));
    pos = pos(1);
end

cTimelapse=cExperiment.returnTimelapse(pos);

if nargin<3 || isempty(TP)
    TP = randperm(length(cTimelapse.timepointsToProcess));
    TP = cTimelapse.timepointsToProcess( TP(1) );
end

cTimelapse = cExperiment.returnTimelapse(pos);

if nargin<4 || isempty(channel)
    
    fprintf('\n\n please select the channel you wish to use for identifying traps by pressing the UP and DOWN arrows on you keyboard.\nThe channel this GUI is on when you close it will be the one used.\n\n'); 
    
    channel_display_gui = cTimelapseDisplay(cTimelapse,1,[TP,TP]);
    channel_display_gui.gui_help = ['please select the channel you wish to use for identifying traps by pressing the up and down arrows on your keyboard.',...
                                    'This should be a channel in which the traps are clearly visible',...
                                    ' The channel this GUI is on when you close it will be the one used.'];
    uiwait(channel_display_gui.figure);
    channel = channel_display_gui.channel;
end

if nargin<5
    poses=[];
end

%set the channel for trap detection for all positions based on this
%function.
setTimelapsesProperty(cExperiment,poses,'channelForTrapDetection',channel);

fprintf('please select a single, representative trap in the following image, and then close the image \n\n')

cTimelapse.clearTrapInfo;
trap_select_gui = cTrapSelectDisplay(cTimelapse,cExperiment.cCellVision,TP,channel);
trap_select_gui.trapLocations = [];
trap_select_gui.gui_help = 'please select a single, representative trap in the following image., then close the GUI.You can change your selection by right clicking to remove the previous trap, and left clicking to add a new one.';
trap_select_gui.setImage;
uiwait(trap_select_gui.figure);

TrapIM = cTimelapse.returnTrapsTimepoint(1,TP,channel);

cExperiment.cCellVision.cTrap.trap1 = TrapIM;

cExperiment.cCellVision.identifyTrapOutline;

% image for is set to mean outside of the trapOutline. When the trap Images
% are used in the normal cross correlation, these pixels (outside the
% trapOutline) will be ignored.
BigTrapOutline = imdilate(cExperiment.cCellVision.cTrap.trapOutline,strel('disk',2));

TrapIM(~BigTrapOutline) = mean(TrapIM(BigTrapOutline));

cExperiment.cCellVision.cTrap.trap1 = TrapIM;
cExperiment.cCellVision.cTrap.trap2 = TrapIM;
cExperiment.cCellVision.se.trap = [];


end

