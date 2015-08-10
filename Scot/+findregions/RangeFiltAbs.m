classdef RangeFiltAbs<findregions.FindRegions
    methods
        function obj=RangeFiltAbs (varargin)
            % RangeFiltAbs --- constructor for an object to run the range filt abs thresholding method as a means of finding regions that contain cells in an image
            %
            % Synopsis:  rangeFiltAbsObj = RangeFiltAbs (varargin)
            %                        
            % Output:    rangeFiltAbsObj = object of class RangeFiltAbs

            % Notes:     This constructor defines the requiredFields
            %            and parameters properties. requiredFields tells
            %            the InitialiseFields method of timelapse classes 
            %            which images must be calculated before this
            %            method can be run (in this case AbsImage).
            %            This constructor also defines parameters for this
            %            object (in this case the target image to be
            %            thresholded). The parameter field can be
            %            input optionally using the Matlab convention of 
            %            the parameter name followed by the value. If no
            %            parameter array is input then the default
            %            parameter set will be constructed. When this class 
            %            is used in timelapse segmentation, where defaults
            %            are defined in the SpecifiedParameters field of a
            %            timelapse object, it should be created with a call
            %            to timelapse.getobj which will send the
            %            appropriate parameters.
            %            
            %Create obj.parameters structure and define default parameter values          
            obj.parameters = struct();
            obj.parameters.localabsrange=30;
            obj.parameters.min=100;%Minimum size of found object
            obj.parameters.max=2000;%maximum size of found object
            %Define required fields and images
            obj.requiredImages={'EntropyFilt'; 'Thresholded'; 'AbsImage'; 'FilledAbs'};           
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description='RangeFiltAbs findregions method. Designed for segmentation of yeast cells using DIC images as the main target. Creates an image representing the difference of each pixel''s value from the local mean intensity. Fills that image - the area within most cells should now have a uniform intensity value. These uniform areas are found by a range filter. To exclude objects unlikely to be cells a simple threshold is applied to an entropy-filtered image. Objects that are not found by that method are excluded from the range filtered result.';
            obj.paramHelp.localabsrange = 'Parameter ''localabsrange'': Determines the size (in pixels) of the local area used to calculate the local mean intensity.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This method does not use any other method or level classes

        end
        function paramCheck=checkParams (obj, timelapseObj)
            % checkParams --- checks if the parameters of a RangeFiltAbs object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj, timelapseObj)
            %
            % Input:	obj = an object of class RangeFiltAbs
            %           timelapseObj = an object of a Timelapse class
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 	

            paramCheck='Parameter localabsrange must be a number larger than 1 and smaller than half the image size.';
            %obj.parameters.localabsrange must be smaller than half the
            %image size
            if isnumeric obj.parameters.localabsrange
                if obj.parameters.localabsrange<timelapseObj.ImageSize(1) || obj.parameters.localabsrange>1;
                   paramCheck='OK';                    
                end
            end            
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
           % initializeFields --- Creates the images required for the RangeFiltAbs method to run
           %
           % Synopsis:  obj = initializeFields (obj, inputObj)
           %            inputObj = an object of a level class.
           %                        
           % Output:    inputObj = an object of a level class.
           %            fieldHistory = structure, details any other method classes used to initialize fields

           % Notes:     
           
           fieldHistory=struct('objects', {},'fieldnames',{});%No method objects are used so this remains empty.
                   
           if ~isfield(inputObj.RequiredImages,'EntropyFilt')
               inputObj.RequiredImages.EntropyFilt=entropyfilt(inputObj.Target);
           end
           
           if ~isfield(inputObj.RequiredImages,'Thresholded')
               inputObj.RequiredImages.Thresholded=imfill(im2bw(inputObj.RequiredImages.EntropyFilt, graythresh(inputObj.RequiredImages.EntropyFilt)),'holes');
           end
           
           if ~isfield(inputObj.RequiredImages,'AbsImage')
               inputObj.RequiredImages.AbsImage=localabs(inputObj.Target, obj.parameters.localabsrange); 
           end
            
           if ~isfield(inputObj.RequiredImages,'FilledAbs')
               inputObj.RequiredImages.FilledAbs=imfill(inputObj.RequiredImages.AbsImage,'holes');
           end            
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for RangeFiltAbs, creates binary result by applying range filter to FilledAbs image      
            %
            % Synopsis:  inputObj = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class RangeFiltAbs
            %            inputObj = an object carrying the data to be thresholded
            %
            % Output:    inputObj = the input object with its RequiredImages.Bin field modified or created

            % Notes:     
            fieldHistory=struct('fieldnames',{},'objects',{});
            ranged=rangefilt(inputObj.RequiredImages.FilledAbs);
            result=false(size(ranged));
            result(ranged==0)=true;
            result=bwareaopen(result,30);
            result(inputObj.RequiredImages.Thresholded==0)=false;
            result=imfill(result,'holes');
            if isfield('inputObj.RequiredImages','Bin')
                inputObj.RequiredImages.Bin(:,:, size(inputObj.RequiredImages.Bin,3))=result;
            else
                inputObj.RequiredImages.Bin(:,:, 1)=result;
            end
            inputObj=obj.removeMinMax(inputObj);

        end
    end
end