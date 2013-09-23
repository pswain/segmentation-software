classdef Threshold<findregions.FindRegions
    methods
        function obj=Threshold (varargin)
            % Threshold --- constructor for an object to run the simple Matlab thresholding method
            %
            % Synopsis:  obj = Threshold (varargin)
            %                        
            % Output:    obj = object of class Threshold

            % Notes:     Constructor for a very basic findregions class,
            %            which simply applies the standard Matlab
            %            thresholding function im2Bw on the target image
            %            (after median filtering).            
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.level='otsu';%Default value - will calculate the threshold level using the Ostu method.
            
            %Define required fields and images
            obj.requiredImages={'MedianFiltered'};
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description='Simple thresholding using the Matlab function im2bw. Applies a median filter to reduce noise before thresholding.';
            obj.paramHelp.level = 'Parameter ''level'': Determines the threshold intensity value. Can be ''otsu'', which will calculate the value using Ostsu''s method. Or can be a value between 0 and 1, where 1 is the maximum intensity value for the type of image (eg 255 for an 8 bit grayscale image)';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This class does not use any other method or level classes

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
           paramCheck='Parameter: level must be either ''otsu'' or a number between 0 and 1';
           if ischar(obj.parameters.level)
               if strcmp(obj.parameters.level,'otsu') || strcmp(obj.parameters.level,'Otsu')
                   paramCheck='OK';
               end
           else
               if isnumeric (obj.parameters.level)
                  if obj.parameters.level>0 && obj.parameters.level<1
                    paramCheck='OK';
                  end
               end
           end                
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the median filtered image required for the Threshold method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class Threshold
            %            inputObj = an object of a level class.

            % Notes:     Applies Matlab function medfilt2 to create median
            %            filtered image.
            
           fieldHistory=struct('objects', {},'fieldnames',{});           
           if ~isfield (inputObj.RequiredImages,'MedianFiltered')
              inputObj.RequiredImages.MedianFiltered=medfilt2(inputObj.Target);
           end
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for Threshold, uses Matlab function im2bw to perform standard thresholding on the .Target image of the input object.
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class Threshold
            %            inputObj = an object carrying the data to be thresholded
            %
            % Output:    result = 2d binary matrix, result of thresholding

            % Notes:     This method requires that MIJ has been started
            %            before it is run. The inputObj must have the
            %            property inputObj.RequiredImages.ThreshTarget
            %            (image to be thresholded)
            fieldHistory=struct('fieldnames',{},'objects',{});
            threshTarget = inputObj.RequiredImages.MedianFiltered;           
            if ischar(obj.parameters.level)
                if strcmp(obj.parameters.level,'otsu') || strcmp(obj.parameters.level,'Otsu')
                    level=graythresh(threshTarget);
                
                end
            else
                level=obj.parameters.level;
            end
            result=im2bw(threshTarget, level);
            result=imfill(result,'holes');
            if ~isfield (inputObj.RequiredImages,'Bin')
                inputObj.RequiredImages.Bin=result;
            else
                inputObj.RequiredImages.Bin(:,:, size(inputObj.RequiredImages.Bin,3))=result;
            end
        end
    end
end