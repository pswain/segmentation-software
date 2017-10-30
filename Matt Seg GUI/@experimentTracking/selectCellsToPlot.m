function selectCellsToPlot(cExperiment,cCellVision,positionsToIdentify,channel,trap_by_trap)
% function selectCellsToPlot(cExperiment,cCellVision,positionsToIdentify,channel,trap_by_trap)
%
% all fairly self evident. trap_by_trap is a boolean. if true will only
% show traps one at a time, only showing those with cells already auto
% selected. Can be a little easier on the eye when selecting cells.
if nargin<3 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end
   
if nargin<4 || isempty(channel)
    channel =1;
end

if nargin<5 || isempty(trap_by_trap)
    options = {'trap by trap','standard grid'};
    [button_pressed] = questdlg('would you like to show the cells trap by trap, showing only those traps with selected cells, or show all the traps in a large grid (the standard way)?',...
                                            'trap by trap:',...
                                        options{1},options{2},options{2});

    trap_by_trap = strcmp(button_pressed,options{1});

end

%% Load timelapses

% Start logging protocol
cExperiment.logger.start_protocol('selecting cells',length(positionsToIdentify));
try
    
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    cTimelapse=loadCurrentTimelapse(cExperiment,currentPos);
    if trap_by_trap
        [traps_to_show,~] = find(cTimelapse.cellsToPlot);
        traps_to_show = unique(traps_to_show);
        for trapi = 1:length(traps_to_show)
            trap_num = traps_to_show(trapi);
            disp = cTrapDisplayPlot(cTimelapse,trap_num,channel);
            set(disp.figure,'Name',sprintf('selecting cells: position %d of %d; trap %d of %d',i,length(positionsToIdentify),trapi,length(traps_to_show)))
            % this just appends a little help for the experimentTracking
            % version of the GUI.
            disp.gui_help = HelpHoldingFunctions.experimentTracking_cellsToPlotGUI();
            uiwait();
        end
    else
        disp = cTrapDisplayPlot(cTimelapse,[],channel);
        set(disp.figure,'Name',sprintf('selecting cells: position %d of %d',i,length(positionsToIdentify)))
        uiwait();
    end
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end
