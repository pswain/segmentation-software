function selectCellsToPlot(cExperiment,cCellVision,positionsToIdentify,channel,trap_by_trap)
% function selectCellsToPlot(cExperiment,cCellVision,positionsToIdentify,channel,trap_by_trap)
% all fairly self evident. trap_by_trap will only show traps one at a time,
% only showing those with cells already auto selected.
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
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    fprintf('selecting cells for position %s\n',cExperiment.dirs{currentPos})
    load([cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse']);
    if trap_by_trap
        [traps_to_show,~] = find(cTimelapse.cellsToPlot);
        traps_to_show = unique(traps_to_show);
        for trapi = 1:length(traps_to_show)
            trap_num = traps_to_show(trapi);
            disp = cTrapDisplayPlot(cTimelapse,cCellVision,trap_num,channel);
            set(disp.figure,'Name',sprintf('selecting cells: position %d of %d; trap %d of %d',i,length(positionsToIdentify),trapi,length(traps_to_show)))
            uiwait();
        end
    else
        disp = cTrapDisplayPlot(cTimelapse,cCellVision,[],channel);
        set(disp.figure,'Name',sprintf('selecting cells: position %d of %d',i,length(positionsToIdentify)))
        uiwait();
    end
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
