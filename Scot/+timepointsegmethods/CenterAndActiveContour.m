classdef CenterAndActiveContour<timepointsegmethods.TimepointSegMethods
    methods
        function obj=CenterAndActiveContour(varargin)
            % LoopRegions --- constructor for LoopRegions, initialises timepoint segmethods object for: identify regions as binary image then loop through them, segmenting each in turn
            %
            % Synopsis:  obj = LoopRegions()
            %            obj = LoopRegions(parameters)
            %                        
            % Input:     parameters = strings defining parameter values in standard matlab input format: ('Parameter1name',parameter1value,'Parameter2name',etc...
            %
            % Output:    obj = object of class LoopRegions

            % Notes:	 This constructor creates and parameterizes an
            %            object of class LoopRegions. Parameter values are 
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
            obj.parameters.FindEdgesMethod = 'ACRadialPSO';
            obj.paramChoices.FindEdgesMethod='findedges';
      
            %Define required fields and images
            obj.requiredImages={};
            %There are no non-image required fields for this class

            %Define user information
            obj.description='description of CenterAndActiveContour';        
            obj.paramHelp.FindEdgesMethod='description of FindEdgesMethod parameter';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use,
            %in the order in which they are called
            obj.Classes.classnames=obj.parameters.FindEdgesMethod;
            obj.Classes.packagenames='findedges';
                    
        end
        
        function paramCheck = checkParams(obj, timelapseObj)            
            % checkParams --- checks if the parameters of a LoopRegions object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class LoopRegions
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 	

            checked='';
            %obj.parameters.findregions must be the name of a class in the
            %findregions package
            
            findEdgesNames=obj.listMethodClasses('findedges');
            
            if ~any(strcmp(obj.parameters.FindEdgesMethod,findEdgesNames))
                checked=[checked 'Parameter ''FindEdgesMethod'' must be the name of a valid class in the ''findedges'' package'];
            end          
            
            if strcmp(checked,'')
                paramCheck='OK';
            else
                paramCheck=checked;
            end
        end
            
        function [timepointObj fieldHistory]=initializeFields(obj, timepointObj)
            % initializeFields --- creates the images in the timepoint object that are necessary for the LoopRegions method to run
            %
            % Synopsis:  [timepointObj fieldHistory]=initializeFields(obj, timepointObj)
            %                        
            % Input:     obj = an object of class LoopRegions
            %            timepointObj = an object of a Timepoint class
            %
            % Output:    timepointObj = an object of a Timepoint class
            %            fieldHistory = structure, holding the numbers of any method objects that were used to initialize fields and the corresponding field names
            %            
            % Notes:     There is only one required image in this class,
            %            created using a method in the findregions package.
            %            It is saved by the run method of the findregions
            %            method as timepointObj.RequiredImages.Bin
            
            %Initiate the fieldHistory entry for this
            %requiredImage.
            fieldHistory=struct('objects', {},'fieldnames',{});
            %Create the field, using a findregions method class.
            
        end
        
        function timepointObj=run(obj, timepointObj, history)
            % run --- run function for LoopRegions, segments cells by thresholding regions and looping through them.
            %
            % Synopsis:  timepointObj = run(obj,timepointObj)
            %                        
            % Input:     obj = an object of class LoopRegions
            %            timepointObj = an object of a Timepoint class
            %
            % Output:    timepointObj = an object of a Timepoint class

            % Notes:    The call to the Region3 constructor, made for each
            %           region will segment any cells in the region to
            %           completion (ie record their details in
            %           Timelapse.Result and Timelapse.TrackingData. If a
            %           timelapse segmentation method does not call either
            %           Region3 or Timepoint3 then it must record the
            %           segmented cells with a call to the superclass
            %           method recordCells.            
            try
            [timepointObj history] = obj.useMethodClassFromRun(timepointObj, history,'findedges', obj.parameters.FindEdgesMethod);
            catch
                disp('debug point in center and active contour');
            end
            timepointObj.Result = timepointObj.RequiredFields.TempResult;
            %Initialize the timelapse.CurrentCell property - to keep track
            %of the trackingnumbers of each cell in the timepoint
            timepointObj.Timelapse.CurrentCell=1;
            timepointObj=obj.recordCells(timepointObj, history);
            
            
        
            end
    end
end