classdef HoughGrdCentroids<findcentres.FindCentres
    methods
        function obj=HoughGrdCentroids (varargin)
            % CentroidsOfBin --- constructor for an object to run a simple findcentres method that returns the centroids of the latest entry in RequiredImages.Bin
            %
            % Synopsis:  obj = CentroidsOfBin (varargin)
            %                        
            % Output:    obj = object of class CentroidsOfBin

            % Notes:                
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.radrange = [8 25];
            obj.parameters.thresh = 5e3;
            obj.parameters.gauss = 20;
            obj.parameters.minimum_cell_distance = 20;
            
            
            %Define required fields and images
            obj.requiredImages={'FilteredTargetImage'};
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description=['Finds centres by performing a hough transform'...
                '(using the file exchange CircularHoughGrd function) and then' ... 
                ' performing a number of simple operations on the accumulator array to remove '...
                'points that are in the wrong part of the image or too close together'];
            obj.paramHelp.thresh = ['threhsold below which maxima in the accumulator are discarded. If centres are being missed this may be too high. If '...
                'erroneous centers far from cells are being found this may be too low.'];
            obj.paramHelp.radrange = ['the [minimum maximum] radius range over which the accumulator looks for circles. Measured in pixels, must be adjusted '...
                'for magnification changes or detecting small cells'];
            obj.paramHelp.gauss = ['width of gaussian (in pixels) used for smoothing the accumulator array before thresholding and processing. If' ...
                ' many centers are found close to each other for a single cell than try increasing this number. If cells are merged decrease it'];
            obj.paramHelp.minimum_cell_distance = 'Centres closer together than this number (in pixels) are averaged. Cruder than the gauss parameter.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This class does not use any other method classes
            

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
           paramCheck = check_param_numeric(obj,'thresh',paramCheck);
           paramCheck = check_param_numeric(obj,'gauss',paramCheck);
           paramCheck = check_param_numeric(obj,'minimum_cell_distance',paramCheck);
           paramCheck = check_param_numeric(obj,'radrange',paramCheck);
           

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
           field=isfield(inputObj.RequiredImages,'FilteredTargetImage');
           if field
               emp=isempty(inputObj.RequiredImages.FilteredTargetImage);
           end
           if ~field || emp
              filt = fspecial('disk',30);
              im = double(inputObj.Target);
              inputObj.RequiredImages.FilteredTargetImage=im-imfilter(im,filt,'replicate');              
           end

        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for HoughGrdCentroids. Uses a hough
            %         transform to find a 2Daccumulator (basically
            %         probability that every pixel is a circle centre) and
            %         then does some simple operations to try and rule out
            %         some of the local maxima, the rest are given as
            %         centers.
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class CentroidsOfBin
            %            inputObj = an object carrying the data to be operated on
            %
            % Output:    inputObj = level object with inputObj.RequiredFields.Centres created or modified

            % Notes:     
            
            fieldHistory=struct('fieldnames',{},'objects',{});
            
            [accum,~,~] = CircularHough_Grd(inputObj.RequiredImages.FilteredTargetImage, obj.parameters.radrange);
            
            accum = imfilter(accum,fspecial('gaussian',obj.parameters.gauss,1),'replicate');
    
            accum = (accum>obj.parameters.thresh & imregionalmax(accum));
   
            accum = imdilate(accum,strel('disk',floor(obj.parameters.minimum_cell_distance/2),4));
            
            accum = imfill(accum,'holes');
            
            accum = bwmorph(accum,'shrink',Inf);
            
            [Ycenters,Xcenters] = find(accum);
    
            inputObj.RequiredFields.Centres=[Xcenters Ycenters];            
        end
    end
end


function paramCheck = check_param_numeric(obj,name,paramCheck)
%small function to check if a parameter is numeric


if ~isnumeric(obj.parameters.(name))
    paramCheck=[paramCheck ' ' name ' must be a number.'];
end


end