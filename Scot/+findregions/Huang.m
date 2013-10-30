classdef Huang<findregions.FindRegions
    methods
        function obj=Huang (varargin)
            % Huang --- constructor for an object to run the Huang thresholding method as a means of finding regions that contain cells in an image
            %
            % Synopsis:  huangObj = Huang (varargin)
            %                        
            % Output:    huangObj = object of class Huang

            % Notes:     This constructor defines the requiredFields
            %            and parameters properties. requiredFields tells
            %            the InitialiseFields method which images must be
            %            calculated before this method can be run (in 
            %            this case ThreshTarget). This constructor also
            %            defines parameters for this object (in this case
            %            the target image type to be thresholded). 
            %            The parameter field can be input optionally
            %            using the Matlab convention of the parameter 
            %            name followed by the value, eg
            %            obj=Huang('targetimage','EntropyFilt'). If no
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
            obj.parameters.targetimage='Target';%Default value - the main target image for segmentation in this dataset
            
            %Define required fields and images
            obj.requiredImages={'ThreshTarget'};           
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description='Local autothresholding using the ImageJ Huang method.';
            obj.paramHelp.targetimage = 'Parameter ''targetImage'': Default is ''Target''. Determines the input image to which thresholding is applied.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor                     
            obj=obj.changeparams(varargin{:});
            
            %This method does not use any other method or level classes

        end
        
        function paramCheck = checkParams (obj, timelapseObj)
           % checkParams --- checks if the parameters of a Huang object are in range and of the correct type
           %
           % Synopsis: 	paramCheck = checkParams (obj)
           %
           % Input:	obj = an object of class Huang
           %
           % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

           % Notes:
           paramCheck='Parameter: ThreshTarget must be either ''Target'', the main target image for segmentation of this dataset, or ''EntropyFilt'', the result of applying an entropy filter to the target image.';
           if ischar(obj.parameters.targetimage)
               if strcmp(obj.parameters.targetimage,'Target') || strcmp(obj.parameters.targetimage,'EntropyFilt')
                   paramCheck='OK';
               end                          
           end                      
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the ThreshTarget image required for the Huang method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class Huang
            %            inputObj = an object of a level class.

            % Notes:     Copies the main Target image or applies  Matlab
            %            function entropyfilt to create target for
            %            thresholding.
           fieldHistory=struct('objects', {},'fieldnames',{});
           switch obj.parameters.targetimage
               case 'EntropyFilt'
                    inputObj.RequiredImages.ThreshTarget=entropyfilt(inputObj.Target);
               case 'Target'
                   inputObj.RequiredImages.ThreshTarget=inputObj.Target;
           end
            
        end
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for Huang, uses ImageJ to run the Huang thresholding method on an input object
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class Huang
            %            inputObj = an object carrying the data to be thresholded
            %
            % Output:    result = 2d binary matrix, result of thresholding

            % Notes:     This method requires that MIJ has been started
            %            before it is run. The inputObj must have the
            %            property inputObj.RequiredImages.ThreshTarget
            %            (image to be thresholded)
            fieldHistory=struct('fieldnames',{},'objects',{});
            MIJ.createImage(inputObj.RequiredImages.ThreshTarget);
            MIJ.run('8-bit');
            MIJ.run('Auto Threshold', 'method=Huang white');
            huang=MIJ.getCurrentImage;
            result=false(size(inputObj.RequiredImages.ThreshTarget));
            result(huang==255)=1;
            result=imfill(result,'holes');
            if ~isfield (inputObj.RequiredImages,'Bin')
                inputObj.RequiredImages.Bin=result;
            else
                inputObj.RequiredImages.Bin(:,:, size(inputObj.RequiredImages.Bin,3))=result;
            end
            MIJ.run('Close All')            
        end
    end
end