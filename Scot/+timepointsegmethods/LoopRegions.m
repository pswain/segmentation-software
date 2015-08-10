classdef LoopRegions<timepointsegmethods.TimepointSegMethods
    methods
        function obj=LoopRegions(varargin)
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
            obj.parameters.findregions='Huang';%default region finding method. NOTE: If a parameter defines use of another class then it should also be written to obj.Classes, after the call to changeparams.
            obj.paramChoices.findregions='findregions';
            %Defining a paramchoices entry for this parameter specifies that there are a limited number of parameter values - to be selected from a drop down list.
            %In this case the possible values are the names of classes in the findregions package
            
            obj.parameters.minsize=200;%minimum size of an object in pixels that will be considered a region
      
            %Define required fields and images
            obj.requiredImages={'Bin'};
            %There are no non-image required fields for this class

            %Define user information
            obj.description='LoopRegions: Runs a FindRegions method to identify regions within the input image. Then loops through the objects in the resulting binary image, creating a Region3 object in each to segment cells within that region.';        
            obj.paramHelp.findregions = 'Parameter ''findregions'': The name of a method in the findregions package that will be used to identify regions within the image';
            obj.paramHelp.minsize='Parameter ''minsize'': Objects that have fewer pixels than minsize will not be considered to be regions and will be ignored';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use,
            %in the order in which they are called
            obj.Classes(1).classnames=obj.parameters.findregions;
            obj.Classes(1).packagenames='findregions';
            obj.Classes(2).classnames='Region';
            obj.Classes(2).packagenames='Level';
                    
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
            findRegionsNames=obj.listMethodClasses('findregions');
            
            if ~any(strcmp(obj.parameters.findregions,findRegionsNames))
                checked=[checked 'Parameter ''findregions'' must be the name of a valid class in the ''findregions'' package'];
            end
            
            if obj.parameters.minsize>timelapseObj.ImageSize(1)*timelapseObj.ImageSize(2)
                checked=[checked 'Parameter ''minsize'' must be smaller than the size of the image.'];
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
            if ~isfield(timepointObj.RequiredImages,'Bin')
                [timepointObj fieldHistory]=obj.useMethodClass(obj,timepointObj, fieldHistory, 'Bin', 'findregions', obj.parameters.findregions);
            end
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
            
            %Initialize the timelapse.CurrentCell property - to keep track
            %of the trackingnumbers of each cell in the timepoint
            timepointObj.Timelapse.CurrentCell=1;
            %Get properties of the connected objects defined by timepointObj.Bin
            STATS=regionprops(timepointObj.RequiredImages.Bin,'Area','BoundingBox', 'Solidity','Image');
            areas=vertcat(STATS.Area);
            %Retrieve only objects greater than obj.parameters.minsize.
            objects=areas>=obj.parameters.minsize;
            STATS(objects==0)=[];
            boxes=vertcat(STATS.BoundingBox);
            numObjects=size(boxes,1);
            historySize=timepointObj.Timelapse.HistorySize;
            for n=1:numObjects%loop through the objects finding the pixels that represent cell interiors
                ulx=ceil(boxes(n,1));
                uly=ceil(boxes(n,2));%x and y coordinates of upper left corner of this object
                xlength=round(boxes(n,3));
                ylength=round(boxes(n,4));
                %create a region object using the bounding box just
                %defined. Use the new segmentation version of the region
                %constructor method (Region3). 
                showMessage(strcat('segmenting region',num2str(n)));%comment for speed
                region=Region3(timepointObj,timepointObj.Timelapse,[ulx uly xlength ylength], history);
                %If there is no call to region3 create a binary image stack
                %representing cell interiors (timepointObj.Result) then
                %call:
                %timepointObj=obj.recordCells(timepointObj, history);
                %This will make records in the timelapse.Result and
                %timelapse.TrackingData properties.
                timepointObj.Timelapse.showProgress(timepointObj.Target);%Comment for speed
                timepointObj.Timelapse.HistorySize=historySize;%Restore the history size from before the loop was run
            end
        
            end
    end
end