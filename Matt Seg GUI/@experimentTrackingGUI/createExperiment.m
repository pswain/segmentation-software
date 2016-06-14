function createExperiment(cExpGUI)

cExpGUI.cExperiment=experimentTracking();

% createTimelapsePositions given with explicit arguments so that
% magnification and imScale are not set in the GUI. These are generally
% confusing arguments that are not widely used and necessarily supported.
% This way they will not be used until again supported and 
cExpGUI.cExperiment.createTimelapsePositions([],'all',...
                                            [],[],[],...
                                            60,[],[]);

set(cExpGUI.posList,'Value',1);
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);

set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
cExpGUI.channel = 1;

cExpGUI.cCellVision = cExpGUI.cExperiment.cCellVision;
set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);
