classdef convHullOfBin<cellsegmethods.EdgeSuperClass  
    methods
        function obj=convHullOfBin(varargin)
            % convHullOfBin --- constructor for convHullOfBin, initialises cellsegmethods object for: make convex hull of binary input
            %
            % Synopsis:  convHullOfBinobj = convHullOfBin()
            %                        
            % Input:     
            %
            % Output:    convHullOfBinobj = object of class convHullOfBin

            % Notes:	 This constructor creates and parameterizes an
            %            object of class convHullOfBin. Parameter values are 
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
            obj.parameters=struct;
            obj.parameters.disksize=2;

            %Define required fields and images
            %These required fields are intialized by a method in the EdgeSuperClass
            obj.requiredImages={'ThisCell'};
            obj.requiredFields={'SE'};

            %Define user information
            obj.description='ConvHullOfBin. This method can be used to complete cell segmentation when other methods (eg from the findregions package) have created a binary image that represents an accurate segmentation. This method simply calculates the convex hull of the input binary image and records that as the segmentation result.';        

            obj=obj.changeparams(varargin{:});
		
            %This class does not use any other classes. obj.Classes is left empty.
         
        end
        
        function [oneCellObj fieldHistory]=run(obj, oneCellObj)
            % run --- run function for convHullOfBin, Get convex hull of the thresholded binary image in oneCellObj.ThisCell
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     obj = an object of class convHullOfBin
            %            oneCellObj = an object of a OneCell class
            %
            % Output:    result = 2d logical matrix, shows segmentation result

            % Notes:
            fieldHistory=struct('objects', {},'fieldnames',{});
            oneCellObj.Result=obj.convHull(oneCellObj.RequiredImages.ThisCell);
        end
    end
    methods (Static)
        function [result]=convHull(thisCell)
            % convHull --- Returns the convex hull of the single object in an input binary image
            %
            % Synopsis:  result = convHull(thisCell)
            %                        
            % Input:     thisCell = 2d logical matrix, image having a single contiguious white object
            %
            % Output:    result = 2d logical matrix, convex hull of the object in the input image

            % Notes:     This method assumes that the thresholding method
            %            applied to the whole image at a given timepoint
            %            has given a good segmentation result for each
            %            cell. Simply applies a convex hull to that result.
            convexProps=regionprops(thisCell,'ConvexImage','BoundingBox');
            convhull=convexProps(1).ConvexImage;
            %need to put this back in the right place in an image the size
            %of the original
            result=false(size(thisCell));
            boxs=vertcat(convexProps.BoundingBox);
            topLeftx=ceil(boxs(1,1));
            topLefty=ceil(boxs(1,2));  
            lengthx=boxs(1,3)-1;
            lengthy=boxs(1,4)-1;        
            result(topLefty:topLefty+lengthy,topLeftx:topLeftx+lengthx)=convhull;        
        end
    end
end