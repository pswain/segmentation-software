classdef Segmethod_2<cellsegmethods.FillEdgeSuperclass   
    methods
        function obj=Segmethod_2(varargin)
            % segmethod_2 --- constructor for segmethod_2, initialises cellsegmethods object for: canny on image, fill in holes.
            %
            % Synopsis:  segmethod_2obj = segmethod_2()
            %            segmethod_2obj = segmethod_2(parameters)
		%
            % Input:     parameters = cell array, parameters names and values in standard Matlab format
            %
            % Output:    segmethod_2obj = object of class segmethod_2

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_2. Parameter values are 
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
            obj.requiredImages={'EdgeImage';'Watershed';'ThisCell'};
            obj.requiredFields={'SE';'BoundingBox'};
            
            %Define user information
            obj.description='Edge-based segmentation method 2. Creates an edge image, then fills in holes in the image. Small features are then removed by image opening. Differs from Segmethod_1 in that the outermost connected object in the edge image is not removed.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
		
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

            %This class does not use any other classes. obj.Classes is left empty.
        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_2 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_2
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
            % run --- run function for segmethod_2, creates result for canny on image, fill in holes, image open.
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     oneCellObj = an object of a OneCell class
            %
            % Output:    oneCellObj = 2d logical matrix, shows segmentation result

            % Notes:     
            result=obj.fillEdge(oneCellObj.RequiredImages.EdgeImage,oneCellObj.RequiredFields.SE,oneCellObj.RequiredImages.Watershed);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(result,oneCellObj.RequiredFields.SE);
            end 
        end
    end
end