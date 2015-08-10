classdef deleteCell<edittimelapse.EditTimelapse
    properties
        frame
        cellnumber
    end
    
    methods
        function obj=deleteCell(varargin)
            % deleteCell --- constructor for deleteCell, initialises editsegmentation object for deleting a single cell at an input timepoint
            %
            % Synopsis:  obj = deleteCell()
            %            obj = deleteCell(parameters)
            %                        
            % Input:     parameters = strings defining parameter values in standard matlab input format: ('Parameter1name',parameter1value,'Parameter2name',etc...
            %
            % Output:    obj = object of class LoopRegions

            % Notes:	 This constructor creates and parameterizes an
            %            object of class deleteCell. Parameter values are 
            %            written to the obj.parameters structure. Default
            %            values are defined in the constructor but any
            %            input values take precedence over these
            %            (obj.parameters is changed in that case through a 
            %            call to the superclass method changeparams). The 
            %            constructor also defines the requiredFields and 
            %            requiredImages properties (both are cell arrays of
            %            strings). These list the images and fields that
            %            must be created before the run method is called.
            %            Any required images are displayed in the gui for
            %            the user to evaluate during segmentation editing. 
            %            The constructor also optionally defines user
            %            information through the string obj.description and
            %            the parameter descriptions in obj.paramHelp.     
            
            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
            obj.parameters.cellnumber=1;
            obj.parameters.frame=1;
                 
            %There are no required fields or images for this class

            %Define user information
            obj.description='deleteCell: Removes a segmented cell from a single timepoint of a segmented timelapse. Used in timelapse editing to remove false positive segmentations. Use the alternative method ''deleteCellAtAllTps'' to eliminate this cellnumber from all timepoints.';        
            obj.paramHelp.cellnumber = 'Parameter ''cellnumber'': The number of the cell to remove';
            obj.paramHelp.frame='Parameter ''frame'': The time point (frame) at which the cell is to be removed.';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This method uses no other classes.
            
        end
        
        function timelapseObj=run(obj, timelapseObj)
            % run --- run method for deleteCell, removes one cell at a single timepoint from a timelapse dataset
            %
            % Synopsis:  timelapseObj=run(obj, timelapseObj)
            %                        
            % Input:     obj = an object of class deleteCell
            %            timelapseObj = an object of a Timelapse class
            %
            % Output:    timelapseObj = an object of a Timelapse class

            % Notes:	  
            
            
            showMessage('Deleting cell from current timepoint');
            %Get the tracking number of the cell at the current timepoint
            trackingnumber=timelapseObj.gettrackingnumber(obj.cellnumber, obj.frame);            
            
            if trackingnumber>0
            
            %TrackingData
            timelapseObj.TrackingData(obj.frame).cells(trackingnumber).cellnumber=nan;
            timelapseObj.TrackingData(obj.frame).cells(trackingnumber).trackingnumber=nan;

            %Result and displayresult
            timelapseObj.DisplayResult(obj.frame).timepoints(timelapseObj.Result(obj.frame).timepoints(trackingnumber).slices)=false;
            %Record deleted slice
            timelapseObj.Result(obj.frame).timepoints(trackingnumber).deletedslices=timelapseObj.Result(obj.frame).timepoints(trackingnumber).slices;
            %Remove slice from result stack
            timelapseObj.Result(obj.frame).timepoints(trackingnumber).slices=[];
            
            
            %Cell entry in the LevelObjects array (if any)
            if ~isempty(timelapseObj.LevelObjects)
                thisFrameCells=timelapseObj.LevelObjects.Frame==obj.frame & [timelapseObj.LevelObjects.TrackingNumber==trackingnumber];
                timelapseObj.LevelObjects.ObjectNumber(thisFrameCells)=[];
                timelapseObj.LevelObjects.Type(thisFrameCells)=[];
                timelapseObj.LevelObjects.ObjectNumber(thisFrameCells)=[];
                timelapseObj.LevelObjects.RunMethod(thisFrameCells)=[];
                timelapseObj.LevelObjects.SegMethod(thisFrameCells)=[];
                timelapseObj.LevelObjects.Timelapse(thisFrameCells)=[];
                timelapseObj.LevelObjects.Frame(thisFrameCells)=[];
                timelapseObj.LevelObjects.Position(thisFrameCells)=[];
                timelapseObj.LevelObjects.Timepoint(thisFrameCells)=[];
                timelapseObj.LevelObjects.Region(thisFrameCells)=[];
                timelapseObj.LevelObjects.TrackingNumber(thisFrameCells)=[];
                timelapseObj.LevelObjects.CatchmentBasin(thisFrameCells)=[];
                timelapseObj.LevelObjects.Centroid(thisFrameCells)=[];
            end
            %Data - set value for this cell to nan in all segmented data fields
            if ~isempty(timelapseObj.Data)
                dataFields=fields(timelapseObj.Data);
                for n=1:size(dataFields,1)
                    timelapseObj.Data.(dataFields{n})(obj.cellnumber,obj.frame)=nan;
                end
                %Display message
                showMessage('Cell deleted');
            end
            end
        end
    end
end