classdef OneCell2<OneCell
    properties   
        MethodObject%Object used in segmentation of the region
    end

    methods   
        function obj=OneCell2(timelapseObj, index)            
            % OneCell2 --- constructor for OneCell2 object, recreates OneCell object based on information stored in Timelapse.LevelObjects
            %
            % Synopsis:  obj = OneCell2 (timelapseObj, index)
            %            obj = OneCell2 ('Blank')
            %
            % Input:     timelapseObj = an object of a Timelapse class
            %            index = integer, the index to the entry for the OneCell object required, in the timelapseObj.LevelObjects structure
            %            
            % Output:    obj = object of class OneCell2          
            
            %Notes - Use the alternative class OneCell3 for segmenting new
            %        cells. This constructor is used to create a OneCell
            %        object from information stored in
            %        timelapseObj.LevelObjects. This avoids the memory cost
            %        of saving the actual Region objects. It is called by 
            %        the Timelapse method levelObjFromNumber. This
            %        constructor will also take a string input - returns an
            %        empty object in that case for blank constructor of the
            %        copy function. NB: This constructor does not
            %        initialize the .Region field with a Region
            %        object, it just copies the object number of the
            %        Region object that was stored in
            %        timlapseObj.LevelObjects (This is in case an object 
            %        with the same number already exists in the workspace. 
            %        You should search for such an object and if you don't
            %        find one call levelObjFromNumber to create it).
                   

            if ~ischar(timelapseObj)
               obj.ObjectNumber=timelapseObj.LevelObjects.ObjectNumber(index);
               obj.RunMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.RunMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.SegMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.SegMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.Timelapse = timelapseObj;
               obj.TopLeftx=timelapseObj.LevelObjects.Position(index,1);
               obj.TopLefty=timelapseObj.LevelObjects.Position(index,2);
               obj.xLength=timelapseObj.LevelObjects.Position(index,3);
               obj.yLength=timelapseObj.LevelObjects.Position(index,4);
               obj.CentroidX=timelapseObj.LevelObjects.Centroid(index,1);
               obj.CentroidY=timelapseObj.LevelObjects.Centroid(index,2);
               obj.TrackingNumber=timelapseObj.LevelObjects.TrackingNumber(index);
               obj.CatchmentBasin=timelapseObj.LevelObjects.CatchmentBasin(index);
               obj.Region=timelapseObj.LevelObjects.Region(index);%Note - this is not a region object, just an objectnumber
               
            end           
        end
        
        
        function obj=initializeFields(obj)
           %This method should recover the Result and Target images for
           %this cell.
           obj.Region=obj.Region.initializeFields;
           obj.Target=obj.Region.Target;
           region=[obj.Region.TopLeftx obj.Region.TopLefty obj.Region.xLength obj.Region.yLength];
           obj.FullSizeResult=obj.Timelapse.Result(obj.Region.Timepoint.Frame).timepoints(obj.TrackingNumber).slices;
           obj.Result=obj.FullSizeResult(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1);
        end
        
    end  
end

    
    
    



