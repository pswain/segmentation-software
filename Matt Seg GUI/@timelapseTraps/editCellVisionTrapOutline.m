function cCellVision = editCellVisionTrapOutline(cTimelapse, cCellVision,TP,TI,channel )
%cCellVision = editCellVisionTrapOutline( cCellVision,TP,TI,channel )
%little method to change the trap outline of cCellVisionto be more representative in the current
%timelapse.

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


TrapIM = cTimelapse.returnTrapsTimepoint(TI,TP,channel);

cCellVision.cTrap.trap1 = TrapIM;

cCellVision.identifyTrapOutline;
%cCellVision.cTrap.trapOutline = ACTrapFunctions.make_trap_pixels_from_image(double(TrapIM));

%experimental section to change the trap images to make the trap detection more consistent.

BigTrapOutline = imdilate(cCellVision.cTrap.trapOutline,strel('disk',2));

TrapIM = cTimelapse.returnTrapsTimepoint(TI,TP,1);

TrapIM(~BigTrapOutline) = mean(TrapIM(BigTrapOutline));

cCellVision.cTrap.trap1 = TrapIM;
cCellVision.cTrap.trap2 = TrapIM;


end

