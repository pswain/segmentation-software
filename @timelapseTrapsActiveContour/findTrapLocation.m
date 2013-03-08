function ttacObject = findTrapLocation(ttacObject,TimePoints)
%function ttacObject = findTrapLocation(ttacObject,timelapseTrapsObject,TimePoints)

%function to go through the images in the timelapseTraps Object, find the
%location of the traps, and store it as a sparse matrix in the ttacObject
%(timlapsetrapsActiveContour). This will be done for the timepoints stated,
%though 'all' is also an option, in which case all timepoints will be
%processed.

%ttacObject    -    an object of the timelapseTrapsActiveContour class
%Timepoints    -    either an array of Timepoints for which you want to find the
%                   traps (i.e. 1:10, [1 5 8]) or the string 'all' to find
%                   all the traps in the timelapse

%value used to initialize the sparse array
maxTrapNumber = 100;

%number of timepoints in the ttacObject.TimelapseTraps object
TimelapseTimepoints = size(ttacObject.TimelapseTraps.cTimepoint,2);

if ttacObject.TrapPresentBoolean

    %Read in the first file just to get the size of the images.
    
    ImStack = ttacObject.TimelapseTraps.returnSingleTimepoint(TimePoints(1));
%     ImStack = imread([ttacObject.TimelapseTraps.timelapseDir '\' ttacObject.TimelapseTraps.cTimepoint(TimePoints(1)).filename{1}((end-33):end)]);
%     ImStack = imrotate(ImStack,ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
%     

    %if trap locations has not been initialised then initialise it to an array
    %of spare matrices of the length of the number of timepoints in 
    if isempty(ttacObject.TrapLocation)
        
        ttacObject.TrapLocation = cell(1,TimelapseTimepoints);
        
        [ttacObject.TrapLocation{:}] = deal(spalloc(size(ImStack,1),size(ImStack,2),maxTrapNumber));
        
    end
    
   
    if all(ismember(TimePoints,1:TimelapseTimepoints))
         fprintf('locating traps\n')
         ImStack = zeros(size(ImStack,1),size(ImStack,1),length(TimePoints));

        for tp = 1:length(TimePoints)
            ImStack(:,:,tp) = ttacObject.TimelapseTraps.returnSingleTimepoint(tp);
%             ImStack(:,:,tp) = imread([ttacObject.TimelapseTraps.timelapseDir '\' ttacObject.TimelapseTraps.cTimepoint(TimePoints(tp)).filename{1}((end-33):end)]);%imread(ttacObject.TimelapseTraps.cTimepoint(Timepoints(tp)).filename{1});
%             ImStack(:,:,tp) = imrotate(ImStack(:,:,tp),ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
        end
         
        ResultOfSearch = ACTrapFunctions.findTraps(ImStack,ttacObject.TrapGridImage,ttacObject.TrapImage);
        [ttacObject.TrapLocation{TimePoints}] = deal(ResultOfSearch{:});
            
    else
        error('one of the timepoints submitted to findTrapLocations is not a valid timpoint')
    end
    
fprintf('finished locating traps \n')
end

end