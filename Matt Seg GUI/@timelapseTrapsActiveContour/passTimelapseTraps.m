function ttacObject = passTimelapseTraps(ttacObject,timelapseTraps)
%function to receive a timelapseTraps object and save it as a property of
%the ttacObject, reseting any fields that are specific to the timelapse
%being inspected.

ttacObject.TimelapseTraps = timelapseTraps;

ttacObject.TrapPresentBoolean = timelapseTraps.trapsPresent;

ttacObject.TrapLocation = [];

if ttacObject.TrapPresentBoolean 

    ttacObject.TrapImageSize = [2*timelapseTraps.cTrapSize.bb_height + 1   2*timelapseTraps.cTrapSize.bb_width + 1];
else
    ttacObject.TrapImageSize = timelapseTraps.imSize;

end
ttacObject.LengthOfTimelapse = length(timelapseTraps.cTimepoint);


end