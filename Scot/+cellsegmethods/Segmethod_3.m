classdef Segmethod_3<cellsegmethods.FillEdgeSuperclass    
    methods
        function obj=Segmethod_3(varargin)
            % Segmethod_3 --- constructor for Segmethod_3, initialises cellsegmethods object for: Canny on abs. Remove outer object. Fill in holes.
            %
            % Synopsis:  Segmethod_3obj = Segmethod_3()
            %            Segmethod_3obj = Segmethod_3(parameters)
            %                        
            % Input:     varargin = holding the object parameters in standard Matlab input format
            %
            % Output:    Segmethod_3obj = object of class Segmethod_3

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_3. Parameter values are 
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
            obj.requiredImages={'AbsEdgeImage';'OuterRemovedAbs';'Watershed';'ThisCell'};
            obj.requiredFields={'SE';'BoundingBox'};

        	%Define user information
            obj.description='Edge-based segmentation method 3. One of several related methods for Saccharomyces cells, that use Canny edge detection to create an image with an outer edge (representing the cell wall-medium boundary) and an inner edge, representing the boundary between the cytoplasm and the cell wall. The aim is to create an object bounded by this inner edge. Creates an ''abs'' image in which pixel values represent the absolute difference between the original pixel value and the local mean intensity. An edge image is created by applying the Canny method to this abs image. Removes the outermost connected object in the edge image then fills in holes. Any small features or thin lines are then removed by image opening. Differs from Segmethod_1 in that edge detection is applied to the abs image, not the original.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
		
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

        	%This class does not use any other classes. obj.Classes is left empty.
            
        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_3 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_3
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
            % run --- run function for Segmethod_3, creates result for canny on abs image, remove outer object, fill in holes.
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     obj = an object of class Segmethod_3
            %            oneCellObj = an object of a OneCell class
            %
            % Output:    oneCellObj = an object of a OneCell class, oneCellObj.Result field shows segmentation result

            % Notes:  
            oneCellObj.Result=obj.fillEdge(oneCellObj.RequiredImages.OuterRemovedAbs,oneCellObj.RequiredFields.SE,oneCellObj.RequiredImages.Watershed);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(oneCellObj.Result,oneCellObj.RequiredFields.SE);
            end
        end
    end
end