classdef FindOuter   
    % Notes:    This class contains the two FindOuter methods used by
    %           several Segmethods classes and OneCell.deleteOuter
    methods (Static)    
        function [meanMinDist closest]=nearestToEdge(varargin)
            % nearestToEdge --- Identifies the nearest object in bin to either the edge of the image or the edge of the bounding box of the object in thisCell
            %
            % Synopsis:  [meanMinDist closest] = nearestToEdge(bin)
            %            [meanMinDist closest] = nearestToEdge(bin, thisCell)
            %                        
            % Input:     bin = 2d logical matrix, binary image
            %            thisCell = 2d logical matrix, binary image containing a single contiguous white object
            %
            % Output:    meanMinDist = vector, mean distance of each pixel in the objects of bin to the relevant edge
            %            closest = integer, index to the entry in regionprops (bin) of the nearest object in bin to the edge

            % Notes:     This is defined as a static method (not requiring 
            %            an instance of the class) so that it can be used 
            %            on different images - eg EdgeImage and 
            %            AbsEdgeImage. Where the second input is supplied  
            %            it should contain a single contiguous object. 
            %            The bounding box of that object defines the edge  
            %            to which distances are measured.

            bin=varargin{1};
            if nargin==1%region is not split
                %Find the object that is closest to the edge of the image
                left=0;
                top=0;
                bottom=size(bin,1)+1;
                right=size(bin,2)+1;
            else%data is from a split region
                thisCell=varargin{2};
                %Find the object that is closest to the edge of the bounding box of
                %the white object in thisCell
                cellProps=regionprops(thisCell,'BoundingBox');
                cellbb=vertcat(cellProps.BoundingBox);
                left=ceil(cellbb(1));
                top=ceil(cellbb(2));
                right=left+round(cellbb(3));
                bottom=top+round(cellbb(4));
            end
                props=regionprops(bin,'PixelList');
                meanMinDist=zeros(size(props,1),1);
                for n=1:size(props,1)
                   p=vertcat(props(n).PixelList);
                   toLeft=(p(:,1)-left)';
                   toRight=(right-p(:,1))';
                   toTop=(p(:,2)-top)';
                   toBottom=(bottom-p(:,2))';
                   minDist1=min(toLeft,toRight);
                   minDist2=min(minDist1,toTop);
                   minDist=min(minDist2,toBottom);
                   meanMinDist(n)=sum(minDist)/numel(minDist);    
                end
                [b closest]=min(meanMinDist);
        end
        function [closest outerImage meanDist]=furthestFromCentroid(edgeImage, thisCell)
            % furthestFromCentroid --- finds the furthest contiguous object in input image from the centroid of the single object in a second input image
            %
            % Synopsis:  [closest outerImage meanDist]=furthestFromCentroid(edgeImage, thisCell)
            %                        
            % Input:     edgeImage = 2d logical matrix, image showing the detected edges in an image to be segmented
            %            thisCell = 2d logical matrix, image showing the approximate position of the target cell within the image region
            %
            % Output:    closest = integer, index to the outer object in the result of regionprops(edgeImage)
            %            outerImage = 2d logical matrix, image showing only the found outermost object
            %            meanDist = vector, square distances from each object in edgeImage to the centroid of the object in thisCell

            % Notes:     This is defined as a static method (not requiring 
            %            an instance of the class) so that it can be used 
            %            to find the outer object from different edge 
            %            images - eg EdgeImage and AbsEdgeImage.

            props=regionprops(edgeImage,'PixelList','PixelIdxList');
            meanDist=zeros(size(props,1),1);
            cellProps=regionprops(thisCell,'Centroid');
            centre=cellProps(1).Centroid;%Define central reference point - measure distances from this.
            for n=1:size(props,1)
                p=vertcat(props(n).PixelList);
                if size(p,1)>3%ignore any objects smaller than 4 pixels in size
                    xdists=(centre(2)-p(:,1));
                    ydists=(centre(1)-p(:,2));   
                    meanDist(n)=mean((xdists.^2)+(ydists.^2));
                else
                    meanDist(n)=0;%won't be found as the maximum
                end
            end
            [b closest]=max(meanDist);
            outerImage=false(size(edgeImage));
            outerPixels=(props(closest).PixelIdxList);
            try
                outerImage(outerPixels)=1;
            catch
                disp ('bug in furthestFromCentroid');
            end
        end
    end
end
    