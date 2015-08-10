function getTrapLocationsFromCellVision(ttacObject)
%get the trapPixels from the trap centers and all that .

imageY = ttacObject.ImageSize(1);

imageX = ttacObject.ImageSize(2);


tempTrapCentre = false([imageY,imageX]);

offset = [0 0]; %[x off set and y off set]

if any(offset~=0)
    
    fprintf('\n\napplying an arbitrary offset - check the outcome of this procedure\n\n');
    
end

for TP=ttacObject.TimelapseTraps.timepointsToProcess;
    if ~isempty(ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations)
        CentrePixels = imageY*(round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).xcenter]-1 + offset(1))) +  round([ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(:).ycenter] + offset(2));
        CentrePixels(CentrePixels<1) = 1;
        CentrePixels(CentrePixels>(imageX*imageY)) = (imageX*imageY);
    else
        CentrePixels = [];
    end
    
    tempTrapCentre(CentrePixels) = true;

    ttacObject.TrapLocation{TP} = sparse(tempTrapCentre);
    
    tempTrapCentre(CentrePixels) = false;
    
end
end