classdef Segmethod_1<cellsegmethods.FillEdgeSuperclass
    methods
        function obj=Segmethod_1(varargin)
            % segmethod_1 --- constructor for segmethod_1, initialises cellsegmethods object for: canny on image, remove outermost object, fill in holes.

            %
            % Synopsis:  Segmethod_1obj = Segmethod_1()
            %            Segmethod_1obj = Segmethod_1(parameters)
            %                        
            % Input:     varargin = holding the object parameters in standard Matlab input format
            %
            % Output:    segmethod_1obj = object of class segmethod_1

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_1. Parameter values are 
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
            %Note: This method class shares certain required fields with other classes
            %based on edge-detection methods. The initializeFields method is therefore
            %also shared, in the EdgeSuperClass.
            obj.requiredImages={'EdgeImage'; 'OuterRemoved'; 'SmallWatershed'; 'ThisCell'};           
            obj.requiredFields={'SE';'BoundingBox'};
            
            %Define user information
            obj.description='Edge-based segmentation method 1. One of several related methods for Saccharomyces cells, that use Canny edge detection to create an image with an outer edge (representing the cell wall-medium boundary) and an inner edge, representing the boundary between the cytoplasm and the cell wall. The aim is to create an object bounded by this inner edge. Creates an edge image by the Canny method, removes the outermost connected object in the edge image. Then fills in holes in the image. Small features are then removed by image opening.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

            %This class does not use any other classes. obj.Classes is left empty.
                    
        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_1 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_1
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

        function oneCellObj=run(obj, oneCellObj)
            % run --- run function for segmethod_1, creates result for canny on image, remove outer object, fill in holes.
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     oneCellObj = an object of a OneCell class
            %
            % Output:    result = 2d logical matrix, result of segmentation

            % Notes:     This method is run from RunCellSegMethods - the 
            %            history is only recorded in timelapse.TrackingData
            %            if the segmentation succeeds.
            oneCellObj.Result=obj.fillEdge(oneCellObj.RequiredImages.OuterRemoved,oneCellObj.RequiredFields.SE,oneCellObj.RequiredImages.SmallWatershed);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(oneCellObj.Result,oneCellObj.RequiredFields.SE);
            end
        end
   end
end