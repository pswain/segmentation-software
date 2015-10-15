classdef OneCell<LevelObject
   properties
       CellNumber%integer, unique identifier for each cell - tracks throughout timelapse - ie same number for a given cell at different timepoints
       TrackingNumber%integer, index to the information on the cell in the timepoint.TrackingData.cells array. Does not track throughout timelapse
       Success%logical, 1 if the cell was successfully segmented, zero if not
       CentroidX%scalar, x-coordinate of the centroid of the cell (within the context of the region bounding box, add region top left x property to get position in the image)
       CentroidY%scalar, y-coordinate of the centroid of the cell (within the context of the region bounding box, add region top left y property to get position in the image)
       ImageSize%2 element vector, size of the original, full size data. Needed to calculate the full size result image
       FullSizeResult%2d logical matrix, showing the result in it's correct position in the input image
       TopLeftThisCellx%integer, x-coordinate of the top left pixel of the bounding box of the single contiguous object in obj.ThisCell
       TopLeftThisCelly%integer, y-coordinate of the top left pixel of the bounding box of the single contiguous object in obj.ThisCell
       xThisCellLength%integer, length in the x dimension of the bounding box of the single object in obj.ThisCell
       yThisCellLength%integer, length in the y dimension of the bounding box of the single object in obj.ThisCell    
       Region%Region object that created this OneCell object (if applicable)
       TopLeftx
       TopLefty
       xLength
       yLength
       CatchmentBasin%integer, where the cell is in a region that has been separated by the watershed transform this is the number of the catchment basin the cell is in.
   end
   methods (Abstract)
      
   end
   methods
       
   end
   methods (Static)
        [deleted outerImage closest]=deleteOuter(varargin);
        [means closest]=nearestToEdge(varargin);
        [closest outerImage meanDist]=furthestFromCentroid(edgeImage, thisCell);
        [filledimg]=fillEdge(varargin);
    end
end