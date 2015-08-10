function InstantiateActiveContourTimelapseTraps( cTimelapse,Parameters )
%InstantiateActiveContourTimelapseTraps( cTimelapse )  a simple method to
%instantiate the TimelapseTrapsActiveContour object associated with an
%instance of the cTimelapse class. Basically just sets it up with default
%parameters.

if nargin<2
    ttacObject = timelapseTrapsActiveContour;
else
    ttacObject = timelapseTrapsActiveContour(Parameters);
end

ttacObject.passTimelapseTraps(cTimelapse);

cTimelapse.ActiveContourObject = ttacObject;

end

