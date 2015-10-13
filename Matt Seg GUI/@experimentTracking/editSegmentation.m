function editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap)

if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
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
    cTimelapse=loadCurrentTimelapse(cExperiment,currentPos);
    cTrapDisplay(cTimelapse,cCellVision,show_overlap);
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
