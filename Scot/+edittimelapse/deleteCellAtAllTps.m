classdef deleteCellAtAllTps<edittimelapse.EditTimelapse
    properties
        cellnumber;
    end
    
    methods
        function obj=deleteCellAtAllTps(varargin)
            % deleteCell --- constructor for deleteCellAtAllTps, initialises editsegmentation object for deleting a cell at all timepoints at which it is tracked
            %
            % Synopsis:  obj = deleteCellAtAllTps()
            %            obj = deleteCellAtAllTps(parameters)
            %                        
            % Input:     parameters = strings defining parameter values in standard matlab input format: ('Parameter1name',parameter1value,'Parameter2name',etc...
            %
            % Output:    obj = object of class LoopRegions

            % Notes:	 This constructor creates and parameterizes an
            %            object of class deleteCellAtAllTps. Parameter
            %            values are written to the obj.parameters structure.
            %            Default values are defined in the constructor but 
            %            any input values take precedence over these.            %          
            %            The constructor also optionally defines user
            %            information through the string obj.description and
            %            the parameter descriptions in obj.paramHelp.     
            
            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
                 
            %There are no required fields or images for this class

            %Define user information
            obj.description='deleteCellAtAllTps: Removes a segmented cell from all timepoints of a segmented timelapse. Used in timelapse editing to remove false positive segmentations. Use the alternative method ''deleteCell'' to eliminate this cellnumber from a single timepoint.';        
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This method uses no other classes.
            
        end
        
        function timelapseObj=run(obj, timelapseObj)
            % run --- run method for deleteCellAtAllTps, removes a cell at all timepoints
            %
            % Synopsis:  timelapseObj=run(obj, timelapseObj)
            %                        
            % Input:     obj = an object of class deleteCellAtAllTps
            %            timelapseObj = an object of a Timelapse class
            %
            % Output:    timelapseObj = an object of a Timelapse class

            % Notes:	    
            
            
            showMessage('Deleting cell from all timepoints');
            blankSlice=sparse(false(size(timelapseObj.Result(1).timepoints(1).slices)));

            for n=1:timelapseObj.TimePoints
                thiscell=[timelapseObj.TrackingData(n).cells.cellnumber]==obj.cellnumber;
                trackingnumber=find(thiscell);
                if ~isempty (trackingnumber)
                    trackingnumber=trackingnumber(1);
                end
                if any(thiscell)        
                    %TrackingData
                    timelapseObj.TrackingData(n).cells(thiscell).cellnumber=nan;
                    timelapseObj.TrackingData(n).cells(thiscell).trackingnumber=nan;
                    %Result and displayresult
                    timelapseObj.DisplayResult(n).timepoints(timelapseObj.Result(n).timepoints(thiscell).slices)=false;
                    timelapseObj.Result(n).timepoints(thiscell).slices=blankSlice;
                end

                if ~isempty (trackingnumber)

                    %Cell entries in the LevelObjects array (if any)
                    thisCell=timelapseObj.LevelObjects.TrackingNumber==trackingnumber;
                    timelapseObj.LevelObjects.ObjectNumber(thisCell)=[];
                    timelapseObj.LevelObjects.Type(thisCell)=[];
                    timelapseObj.LevelObjects.ObjectNumber(thisCell)=[];
                    timelapseObj.LevelObjects.RunMethod(thisCell)=[];
                    timelapseObj.LevelObjects.SegMethod(thisCell)=[];
                    timelapseObj.LevelObjects.Timelapse(thisCell)=[];
                    timelapseObj.LevelObjects.Frame(thisCell)=[];
                    timelapseObj.LevelObjects.Position(thisCell)=[];
                    timelapseObj.LevelObjects.Timepoint(thisCell)=[];
                    timelapseObj.LevelObjects.Region(thisCell)=[];
                    timelapseObj.LevelObjects.TrackingNumber(thisCell)=[];
                    timelapseObj.LevelObjects.Centroid(thisCell)=[];
                end

                    
            end 
            %Data - set value for this cell to nan in all segmented data fields
            if ~isempty(timelapseObj.Data)
                dataFields=fields(timelapseObj.Data);
                for n=1:size(dataFields,1)
                    timelapseObj.Data.(dataFields{n})(obj.cellnumber,:)=nan;
                end
            end
        end
    end
end