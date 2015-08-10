classdef Region4<Region
    properties        
        NumBasins%integer, number of catchment basins in this region
    end
    
    methods
        function [obj]=Region4(timelapseObj, frame, trackingnumber, nearestFrame)
            % Region4 --- constructor for region object, made for cells for which segmentation has previously failed
            %
            % Synopsis:  obj = region4 (timepointObj,trackingnumber, frame)
            %
            % Input:     timelapseObj = an object of a timelapse class
            %            frame = integer, the frame of the timelapse at which this region occurs
            %            trackingnumber = integer, tracking number of a cell in this region at the nearest timepoint at which there is a segmented cell
            %            nearestFrame = integer, the timepoint at which the cell defined by tracking number was segmented 
            %                                               
            % Output:    obj = an object of class region4
           
            % Notes:     Use the alternative class Region3 for segmenting
            %            new cells, or class Region2 for reconstructing
            %            region objects that have been created previously.
            %            Where there is a single input, the string 'Blank'
            %            or no inputs, then an empty object is returned.
            if nargin==4
                coordinates=timelapseObj.TrackingData(nearestFrame).cells(trackingnumber).region;
                obj.TopLeftx=coordinates(1);
                obj.TopLefty=coordinates(2);
                obj.xLength=coordinates(3);
                obj.yLength=coordinates(4);
                obj.Timelapse = timelapseObj;
                obj.Timepoint=timelapseObj.getTimepoint(frame);
                obj.Timepoint.initializeFields;%This will create the Target property
                obj.Target=obj.Timepoint.Target(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
                %Get the segmethod - use the one that was used at the nearest timepoint
                obj.SegMethod=getMethodObject(timelapseObj, 'regionsegmethods', nearestFrame, trackingnumber);
            end
        end%of constructor method
    function obj=makeDisplayResult(obj)
        %MAKE A 2D DISPLAYABLE RESULT FROM THE 3D ENTRY FOR THIS
        %TIMEPOINT IN TIMELAPSEOBJ
        obj.DisplayResult=sum(obj.Result,3);
        %This can be made more sophisticated - to deal with display of
        %overlapping cells.
        end
    function obj=makeResult(obj, timepointObj)
       %COPY THE ENTRY FOR THIS TIMEPOINT FROM THE TIMELAPSE OBJECT
       obj.Result=timepointObj.Result(obj.TopLefty: obj.TopLefty+obj.yLength-1, obj.TopLeftx:obj.TopLeftx+obj.xLength-1,:, timepointObj.Frame);
    end
    end
end