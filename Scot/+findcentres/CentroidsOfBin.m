classdef CentroidsOfBin<findcentres.FindCentres
    methods
        function obj=CentroidsOfBin (varargin)
            % CentroidsOfBin --- constructor for an object to run a simple findcentres method that returns the centroids of the latest entry in RequiredImages.Bin
            %
            % Synopsis:  obj = CentroidsOfBin (varargin)
            %                        
            % Output:    obj = object of class CentroidsOfBin

            % Notes:                
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.minsize=10;
            obj.parameters.binmethod='Huang';
            obj.paramChoices.binmethod='findregions';
            
            %Define required fields and images
            obj.requiredImages={'Bin','FilteredTargetImage'};
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description='Finds the centroid positions of connected objects in a binary image';
            obj.paramHelp.minsize = 'Parameter ''minsize'': number of pixels. Objects smaller than minsize will be ignored.';
            obj.paramHelp.binmethod = 'Parameter ''binmethod'': method for creating the binary image used to define centroid positions.';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use
            obj.Classes.classnames=obj.parameters.binmethod;
            obj.Classes.packagenames='findregions';

        end
        
        function paramCheck=checkParams(obj, timelapseObj)
           % checkParams --- checks if the parameters of a Threshold object are in range and of the correct type
           %
           % Synopsis: 	paramCheck = checkParams (obj)
           %
           % Input:	obj = an object of class LoopBasins
           %
           % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

           % Notes:  
           paramCheck='';
           if ~isnumeric(obj.parameters.minsize)
              paramCheck=[paramCheck 'minsize must be a number.'];
           end
           
           if isempty(paramCheck)
               paramCheck='OK';               
           end            
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the fields and images required for the CentroidsOfBin method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class CentroidsOfBin
            %            inputObj = an object of a level class.

            % Notes:     Uses a method in the findcentres class to create
            % the inputObj.RequiredFields.Centres field.
            
           fieldHistory=struct('objects', {},'fieldnames',{});
           
            if ~isfield(inputObj.RequiredImages,'FilteredTargetImage')
              filt = fspecial('disk',30);
              im = double(inputObj.Target);
              inputObj.RequiredImages.FilteredTargetImage=im-imfilter(im,filt,'replicate');
              
           end

           %Make the Bin field - using the method defined by
           %obj.parameters.binmethod
           [inputObj fieldHistory]=obj.useMethodClass(obj,inputObj, fieldHistory, 'Bin', 'findregions', obj.parameters.binmethod);

           
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for CentroidsOfBin, finds cell outlines from centres and input image
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class CentroidsOfBin
            %            inputObj = an object carrying the data to be operated on
            %
            % Output:    inputObj = level object with inputObj.RequiredFields.Centres created or modified

            % Notes:     
            
            fieldHistory=struct('fieldnames',{},'objects',{});
            binSize=size(inputObj.RequiredImages.Bin,3);
            props=regionprops(inputObj.RequiredImages.Bin(:,:,binSize),'Centroid','Area');
            bigEnough=[props.Area]>=obj.parameters.minsize;
            inputObj.RequiredFields.Centres=vertcat(props(bigEnough).Centroid);            
        end
    end
end