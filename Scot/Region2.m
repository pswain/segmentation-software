classdef Region2<Region
    properties        
        NumBasins%integer, number of catchment basins in this region
        MethodObject%Object used in segmentation of the region
    end
    
    methods
        function [obj]=Region2 (timelapseObj, index)
            % Region2 --- constructor for region2 object, recreates region object based on information stored in Timelapse.LevelObjects
            %
            % Synopsis:  obj = region2 (timelapseObj, index)
            %            obj = region2 ('Blank')
            %
            % Input:     timelapseObj = an object of a Timelapse class
            %            index = integer, the index to the entry for the region object required, in the timelapseObj.LevelObjects structure
            %                                    
            % Output:    obj = an object of class region2
           
            % Notes: Use the alternative class Region3 for segmenting new
            %        cells. This constructor is used to create a Region
            %        object from information stored in
            %        timelapseObj.LevelObjects. This avoids the memory cost
            %        of saving the actual Region objects. It is called by 
            %        the Timelapse method levelObjFromNumber. This
            %        constructor will also take a string input - returns an
            %        empty object in that case for blank constructor of the
            %        copy function. NB: This constructor does not
            %        initialize the .Timepoint field with a timepoint
            %        object, it just copies the object number of the
            %        timepoint object that was stored in
            %        timlapseObj.LevelObjects (This is in case an object 
            %        with the same number already exists in the workspace. 
            %        You should search for such an object and if you don't
            %        find one call levelObjFromNumber to create it).
            
            

            
           if ~ischar(timelapseObj)
               obj.ObjectNumber=timelapseObj.LevelObjects.ObjectNumber(index);
               obj.Frame=timelapseObj.LevelObjects.Frame(index);
               obj.RunMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.RunMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.SegMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.SegMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.Timelapse = timelapseObj;
               obj.TopLeftx=timelapseObj.LevelObjects.Position(index,1);
               obj.TopLefty=timelapseObj.LevelObjects.Position(index,2);
               obj.xLength=timelapseObj.LevelObjects.Position(index,3);
               obj.yLength=timelapseObj.LevelObjects.Position(index,4);
               obj.Timepoint=timelapseObj.LevelObjects.Timepoint(index);%Note - this is not a timepoint object, just an objectnumber
           end          
            
        end%of constructor method
        function obj=initializeFields(obj)
            %Makes the fields required for any run method acting on this
            %region object
            obj.Timepoint=obj.Timepoint.initializeFields;
            obj.Target=obj.Timepoint.Target(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
            slice=0;
            for n=1:size(obj.Timepoint.Result,3);
                if ~isempty (obj.Timepoint.Result)
                    if any(obj.Timepoint.Result(n).slices(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1))
                        slice=slice+1;
                        obj.Result(slice).slices=obj.Timepoint.Result(n).slices(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
                    end
                end
            end
            obj.makeDisplayResult;
        end
    function obj=makeDisplayResult(obj)
        %MAKE A 2D DISPLAYABLE RESULT FROM THE 3D ENTRY FOR THIS
        %TIMEPOINT IN TIMELAPSEOBJ    
        all=false(obj.yLength, obj.xLength);
        for n=1:size(obj.Result,2)
            all(:,:,n)=obj.Result(n).slices;
        end
        obj.DisplayResult=sum(all,3);
        %This can be made more sophisticated - to deal with display of
        %overlapping cells.
        end

    end
end