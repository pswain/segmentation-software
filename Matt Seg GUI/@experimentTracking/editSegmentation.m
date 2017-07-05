function editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap,pos_traps_to_show,channel)
% editSegmentation(cExperiment,cCellVision,positionsToIdentify,show_overlap,pos_traps_to_show,channel)
%
%
% cExperiment             :   object of the experimentTracking class
% cCellVision             :   object of the cellVision class
% positionsToIdentify     :   array of indices position to show. Defaults
%                             to all in cExperiment
% show_overlap            :   logical of whether to show tracking. asks via
%                             GUI if not provided.
% pos_traps_to_show       :   cell array of traps to show at each position
%                             (an array of trap indices for each position
%                             stored in a cell array). Defaults to showing
%                             all traps for each position.
% channel                 :   channel from which to take underlying image.
%                             defaults to 1.
%
% This opens the cTrapDisplay GUI for each position requested, which is the
% GUI used for editing segmentation result by addition and removal of
% cells. 
%
% the GUI's are opened in turn, with each being opened after the present
% one is closed.

if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end

if nargin<5 || isempty(pos_traps_to_show)
    pos_traps_to_show_given = false;
else
    pos_traps_to_show_given = true;
end

if nargin<6 || isempty(channel)
    channel = 1;
end

if nargin<4 || isempty(show_overlap)
    options = {'yes','no'};
    [button_pressed] = questdlg('would you like to colour the cells according to their tracking?',...
                                            'tracking questions:',...
                                        options{1},options{2},options{2});

    show_overlap = strcmp(button_pressed,options{1});

end
    
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    cTimelapse=loadCurrentTimelapse(cExperiment,currentPos);
    
    % in rare cases where active contour parameters have not been set. set
    % them.
    if isempty(cTimelapse.ACParams)
        cTimelapse.ACParams = cExperiment.ActiveContourParameters;
    end
    
    if pos_traps_to_show_given
        traps_to_show = ((pos_traps_to_show{currentPos}(:))');
    else
        traps_to_show = 1:length(cTimelapse.cTimepoint(cTimelapse.timepointsToProcess(1)).trapInfo);
    end
    %if pos_traps_to_show was provided, and the traps_to_show entry is
    %empty, then no traps should be shown for this timelapse and the GUI is
    %not opened.
    if ~(pos_traps_to_show_given && isempty(traps_to_show))
        cTrapDisplay(cTimelapse,cCellVision,show_overlap,channel,traps_to_show);
    end
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
