function trapNumber= getNearestTrapNumber( cData, timepoint, pos )
%GETNEARESTTRAPNUMBER Summary of this function goes here
%   Detailed explanation goes here
trapLocs=cData.cTimelapse.cTimepoint(timepoint).trapLocations;
distances=[];
for i=1:length(trapLocs)
    
    thisDistance=sqrt(((trapLocs(i).xcenter)-pos(2))^2+((trapLocs(i).ycenter)-pos(1))^2);
    distances=[distances thisDistance];

end

minDistance=min(distances);
[randomthrowawayvariable, trapNumber]=find(distances==minDistance);
