function editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap,pos_traps_to_show)
%function editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap,PosTraps)
% PosTraps is a cell array of trap vectors indicating which traps should be
% shown for each position.
if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end

if nargin<5 || isempty(pos_traps_to_show)
    pos_traps_to_show_given = false;
else
    pos_traps_to_show_given = true;
end

if nargin<4 || isempty(show_overlap)
    options = {'yes','no'};
    [button_pressed] = questdlg('would you like to colour the cells according to their tracking?',...
                                            'tracking questions:',...
                                        options{1},options{2},options{2});

    show_overlap = strcmp(button_pressed,options{1});

end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
    if pos_traps_to_show_given
        traps_to_show = ((pos_traps_to_show{currentPos}(:))');
    else
        traps_to_show = 1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo);
    end
    cTrapDisplay(cTimelapse,cCellVision,show_overlap,[],traps_to_show);
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
