classdef Segmethod_7<cellsegmethods.EdgeSuperClass   
    methods
        function obj=Segmethod_7(varargin)
            % Segmethod_7 --- constructor for Segmethod_7, initialises cellsegmethods object for: Get convex hull of all pixels that are not part of the outer object.
            %
            % Synopsis:  Segmethod_7obj = Segmethod_7()
            %            Segmethod_1obj = Segmethod_7(parameters)

            %                        
            % Input:     varargin = holding the object parameters in standard Matlab input format

            %
            % Output:    Segmethod_7obj = object of class Segmethod_7

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_7. Parameter values are 
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
            obj.parameters.disksize=2;

            %Define required fields and images
            %Note: This method class shares certain required fields with other classes
            %based on edge-detection methods. The initializeFields method is therefore
            %also shared, in the EdgeSuperClass.  
            obj.requiredImages={'EdgeImage';'OuterRemoved';'OuterImage';'ThisCell'};
            obj.requiredFields={'SE';'BoundingBox'};

            %Define user information
            obj.description='Edge-based segmentation method 7. One of several related methods for Saccharomyces cells, that use Canny edge detection to create an image with an outer edge (representing the cell wall-medium boundary) and an inner edge, representing the boundary between the cytoplasm and the cell wall. The aim is to create an object bounded by this inner edge. Canny edge detection is applied to the target image. The outermost connected object in the resulting edge image (which may represent the outer boundary) is removed. A convex hull is created, incorporating all remaining edge pixels. Any small projections are removed by morphological opening.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
          
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

            %This class does not use any other classes. obj.Classes is left empty.

        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_7 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_7
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes:
            paramCheck=''; 
            if ~isnumeric(obj.parameters.disksize)
                paramCheck='Parameter ''disksize'' must be a number';
            elseif obj.parameters.disksize>timelapseObj.ImageSize(1)/3
                paramCheck='disksize too large. Choose a number significantly smaller than the image size.';
            end

            if paramCheck=='';
                paramCheck='OK';
            end
	  end



        function [oneCellObj]=run(obj, oneCellObj)
            % run --- run function for Segmethod_7, Get convex hull of all pixels that are not part of the outer object.
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     obj = an object of class Segmethod_7
            %            oneCellObj = an object of a OneCell class
            %
            % Output:    oneCellObj = an object of a OneCell class, shows segmentation result in .Result field

            % Notes:     
            oneCellObj.Result=obj.convInner(oneCellObj.RequiredImages.OuterRemoved, oneCellObj.RequiredImages.OuterImage);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(oneCellObj.Result,oneCellObj.RequiredFields.SE);
            end
        end
    end
    methods (Static)
        function [result]=convInner(outerRemoved, outerImage)
            % convInner --- calculates and returns the convex hull of all contiguous objects in an image except the outermost one
            %
            % Synopsis:  result = convInner(outerRemoved,outerImage)
            %                        
            % Input:     outerRemoved = 2d logical matrix, edge image in which outermost object has been removed
            %            outerImage = 2d logical matrix, image having only the outermost object of an edge image
            %
            % Output:    result = 2d logical matrix, shows result

            % Notes: Canny edge detection on DIC images of yeast normally
            % detects two roughly parallel edges, representing the
            % junctions between the cell interior and the cell wall and the
            % cell wall and the medium. After removing the outermost object
            % (normally representing the outer junction), this method
            % returns an image consisting of the convex hull of all of the
            % remaining edge objects. Works well for cells in which the
            % inner edge has gaps.
            
            if any (outerRemoved(:))%make sure there is at least one edge pixel
                %define a label matrix - outer object pixels have a different
                %colour from all other edge pixels.
                lm=zeros(size(outerRemoved));
                lm(outerRemoved==1)=1;
                lm(outerImage==1)=2;
                %Get the relevant properties of the 2 objects
                convexProps=regionprops(lm,'ConvexImage','BoundingBox');
                convHull=convexProps(1).ConvexImage;
                %need to put this back in the right place in an image the size
                %of the original
                result=false(size(outerRemoved));
                boxs=vertcat(convexProps.BoundingBox);
                topLeftx=ceil(boxs(1,1));
                topLefty=ceil(boxs(1,2));  
                lengthx=boxs(1,3)-1;
                lengthy=boxs(1,4)-1;        
                result(topLefty:topLefty+lengthy,topLeftx:topLeftx+lengthx)=convHull;
            else
                result=outerRemoved;
            end
        end
    end
end