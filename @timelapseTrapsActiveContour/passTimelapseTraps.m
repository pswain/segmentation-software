function ttacObject = passTimelapseTraps(ttacObject,timelapseTraps)
%function to receive a timelapseTraps object and save it as a property of
%the ttacObject, reseting any fields that are specific to the timelapse
%being inspected.

ttacObject.TimelapseTraps = timelapseTraps;

ttacObject.TrapPresentBoolean = timelapseTraps.trapsPresent;

ttacObject.TrapLocation = [];


end