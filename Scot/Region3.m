classdef Region3<Region
    properties        
        NumBasins%integer, number of catchment basins in this region
    end
    
    methods
        function [obj]=Region3(timepointObj,Timelapse, coordinates, history)
            % Region3 --- constructor for region object, segments data
            %
            % Synopsis:  obj = region3 (timepointObj,Timelapse, coordinates)
            %
            % Input:     timepointObj = an object of a timepoint class
            %            coordinates = 4 element vector [topleftx toplefty lengthx lengthy]:
            %            topleftx = integer, x coordinate of the upper left pixel of the region
            %            toplefty = integer, y coordinate of the upper left pixel of the region
            %            lengthx = integer, length in pixels of the x dimension of the region
            %            lengthy = integer, length in pixels of the y dimension of the region
            %            Timelapse = an object of the Timelapse class
            %
            % Output:    obj = an object of class region3
           
            % Notes:     This constructor performs segmentation of the input
            %            region
            
            %Initialise required fields for segmentation
            obj.TopLeftx=coordinates(1);
            obj.TopLefty=coordinates(2);
            obj.xLength=coordinates(3);
            obj.yLength=coordinates(4);
            obj.Timelapse = Timelapse;
            obj.ObjectNumber=obj.Timelapse.NumObjects;
            obj.Timelapse.NumObjects=obj.Timelapse.NumObjects+1;
            obj.Timepoint = timepointObj;        
            %get the run method
            obj.RunMethod=obj.Timelapse.getobj('runmethods','RunRegionSegMethod');              
            %Now populate the images
            obj.Target=obj.Timepoint.Target(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
            %segment the region
            obj=obj.RunMethod.run(obj, history);
            
        end%of constructor method
    end
end