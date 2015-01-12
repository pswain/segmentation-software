function editCellVisionTrapOutline( cExperiment,pos,TI,TP,channel )
% editCellVisionTrapOutline( cExperiment,pos,TI,TP,channel ) changes the trap image and outline of
% cCellVision attached to the cExperiment file. requires the cTimelapse to already have some traps
% imaged. all inputs are optional (other than cExperiment) but and active channel choice is strongly
% recommended

if nargin<2 || isempty(pos)
    pos = randperm(length(cExperiment.dirs));
    pos = pos(1);
end

load(fullfile(cExperiment.saveFolder,[ cExperiment.dirs{pos} 'cTimelapse']),'cTimelapse');

if nargin<3 || isempty(TP)
    TP = randperm(length(cTimelapse.timepointsToProcess));
    TP = cTimelapse.timepointsToProcess( TP(1) );
end

if nargin<4 || isempty(TI)
    TI = randperm(length(cTimelapse.cTimepoint(TP).trapLocations));
    TI = TI(1);
end

if nargin<5 || isempty(channel)
    channel = 1;
end

editCellVisionTrapOutline(cTimelapse, cExperiment.cCellVision,TP,TI,channel);



end

