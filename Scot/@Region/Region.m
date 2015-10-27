classdef Region<LevelObject
    properties
       Frame%integer, number of the current timepoint
       TopLeftx%integer, x coordinate of the top left pixel of the region, in the original, full size image
       TopLefty%integer, y coordinate of the top left pixel of the region, in the original, full size image
       xLength%integer, length in x of the region (in pixels)
       yLength%integer, length in y of the region (in pixels)
       TrackingNumbers%vector, the tracking numbers of cells in the region
       Timepoint%object of a timepoint class, the timepoint that the region is in.
    end
    methods (Abstract)
      
    end
    methods
       
    end
end