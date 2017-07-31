function cCellVision = createCellVisionFromExperiment( cExperiment,pos)
% cCellVision = createCellVisionFromExperiment( cExperiment,pos)
%
% pos     - position from which to select the trap
%
% this is utility function for the cCellVision training scripts. It wraps
% together the constructor and the selection of the trap image, allowing
% the trap template to be selected and an appropriate magnification to be
% chosen.

if nargin<2 || isempty(pos)
    pos = 1;
end
cCellVision = cellVision();

cTimelapse = cExperiment.loadCurrentTimelapse(pos);

fprintf('\n\n please select a timepoint and channel that you wish to use for selecting the trap template\n\n')

gui = cTimelapseDisplay(cTimelapse);
gui.gui_help = HelpHoldingFunctions.cellVision_trap_select_help;
uiwait;

channel = gui.channel;
timepoint = gui.last_timepoint;

hlp_box = helpdlg('we will now decide whether to rescale the images for processing.An image will be shown, and you will be requested to provide a scaling between 0 and 1. When you are happy, Press the '' that''s fine '' button. Otherwise, press the ''try again '' ');
uiwait(hlp_box);
scaling = 1;
try_again = true;
f = figure;
set(f,'Name','scaled image','NumberTitle','Off')
% ask the user to submit scaling values in a while loop until they are
% satisfied with the result.

% in case cTimelapse has no pixels size (shouldn't happen on modern ones)
cTimelapse.determineImSize(1);
while try_again
    % change the cTimelapse pixel size so that it will return the image it
    % would if the cellVision pixel size was set the value determined by
    % the current scaling.
    cellVision_pixel_size = cTimelapse.pixelSize/scaling;
    cTimelapse.scaledImSize = cTimelapse.determineImSize(cellVision_pixel_size);
    cTimelapse.imSize = [];
    image = cTimelapse.returnSingleTimepoint(timepoint,channel);
    figure(f);
    imshow(image,[]);
    quest_ans = questdlg(sprintf('the current scaling value is %2.2f. Are you happy with the image?',scaling),'scaling ok?','that''s fine','try again','that''s fine');
    switch quest_ans
        case 'that''s fine'
            try_again = false;
        case 'try again'
            try_again = true;
            user_scaling = inputdlg({'please submit a new scaling'},'submit scaling',1,{sprintf('%2.2f',scaling)});
            scaling = str2num(user_scaling{1});
    end

end
close(f);
cCellVision.pixelSize =cellVision_pixel_size;
cCellVision.selectTrapTemplate(image);

cCellVision.identifyTrapOutline();

end

