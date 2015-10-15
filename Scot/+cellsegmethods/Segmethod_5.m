classdef Segmethod_5<cellsegmethods.EdgeSuperClass
    methods
        function obj=Segmethod_5(varargin)
            % Segmethod_5 --- constructor for Segmethod_5, initialises cellsegmethods object for: scale down outer object. Fill in holes.
            %
            % Synopsis:  Segmethod_5obj = Segmethod_5()
            %            Segmethod_5obj = Segmethod_5(parameters)

            %                        
            % Input:     varargin = holding the object parameters in standard Matlab input format
            %
            % Output:    Segmethod_5obj = object of class Segmethod_5

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_5. Parameter values are 
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
            obj.requiredImages={'EdgeImage';'OuterRemoved'; 'OuterImage'; 'SmallThisCell'; 'ThisCell'; 'Watershed'};
            obj.requiredFields={ 'SE'; 'BoundingBox'};

            %Define user information
            obj.description='Edge-based segmentation method 5. One of several related methods for Saccharomyces cells, that use Canny edge detection to create an image with an outer edge (representing the cell wall-medium boundary) and an inner edge, representing the boundary between the cytoplasm and the cell wall. The aim is to create an object bounded by this inner edge. Creates an edge image by the Canny method. The outermost connected object in the edge image is approximately the same shape as the cell and is often more complete (with few or no gaps) than the inner edge. Scales this outermost object down to the size of the remaining objects combined. Then fills in holes in the resulting image. Small features are then removed by image opening.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

            %This class does not use any other classes. obj.Classes is left empty.

        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_5 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_5
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
            % run --- run function for Segmethod_5, creates result for scale down outer object. Fill in holes.
            %
            % Synopsis:  oneCellObj = run(oneCellObj)
            %                        
            % Input:     obj = an object of class Segmethod_5
            %            oneCellObj = 
            %
            % Output:    oneCellObj = an object of a OneCell class, shows segmentation result in .Result field

            % Notes:
            oneCellObj.Result=obj.scaleEdgeImage(oneCellObj);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(oneCellObj.Result,oneCellObj.RequiredFields.SE);
            end
        end
    end 
    methods (Static)
        function [filledScaledImg]=scaleEdgeImage(oneCellObj)
            % scaleEdgeImage --- Performs segmentation by scaling down outermost object in edge image, overlaying on remaining edge pixels and filling holes
            %
            % Synopsis:  filledScaledImg = scaleEdgeImage(oneCellObj)
            %                        
            % Input:     oneCellObj = an object of a OneCell class
            %                        
            % Output:    filledScaledImg = 2d logical matrix, shows segmentation result

            % Notes: Canny edge detection on DIC images of yeast normally
            % detects two roughly parallel edges, representing the
            % junctions between the cell interior and the cell wall and the
            % cell wall and the medium. This method attempts to close any
            % gaps in the inner edge so that it can be filled, by adding a
            % scaled down version of the outer edge.           
            
            %check there is something in the edge image
            if any(oneCellObj.RequiredImages.OuterRemoved(:))        
                %bridge the inner and outer images - to complete a perimeter if possible
                outerDeleted=bwmorph(oneCellObj.RequiredImages.OuterRemoved,'bridge');
                outerImg=bwmorph(oneCellObj.RequiredImages.OuterImage,'bridge');
                %get the outer image - within its bounding box (outerimage is same size as edgeimage-need to scale it down).
                outProps=regionprops(outerImg,'Image','BoundingBox');
                outInBox=outProps(1).Image;
                %get position and size of the 2nd closest object to the edge in the original edge image
                [inner redundant redundant2]=cellsegmethods.FindOuter.furthestFromCentroid(outerDeleted,oneCellObj.RequiredImages.ThisCell);
                %identify the bounding box of the 'inner' object (2nd outermost object)
                props=regionprops(outerDeleted,'Image','BoundingBox');
                innerBox=props(inner).BoundingBox;
                innerBox=vertcat(innerBox);
                xInner=ceil(innerBox(1));
                yInner=ceil(innerBox(2));
                lengthInnerx=size(props(inner).Image,2)-1;
                lengthInnery=size(props(inner).Image,1)-1;
                %rescale the outer image to the size of the 2nd closest image to the edge
                outerScaled=imresize(outInBox,size(props(inner).Image));
                %then put outerscaled in an image of its own to add back to outerdeleted
                %has to be the right size
                outerScaledImage2=zeros(size(outerDeleted));
                outerScaledImage2(yInner:yInner+lengthInnery,xInner:xInner+lengthInnerx)=outerScaled;
                %add the scaled outer object to the image with outer removed
                added=outerDeleted|outerScaledImage2;
                added=bwmorph(added,'bridge');%Fill in any single pixel gaps
                added=bwmorph(added,'thin');
                %size of added - if a single cell - it's the same size as oneCellObj.DeleteOuter.OuterDeleted - just return added after filling.
                %if it's a split cell then added is smaller - the size of the bounding box around the binary object in oneCellObj.ThisCell
                %Need to put it back into the right sized image. Also need to add the watershed lines - needed to fill in cell without filling whole image.
                if isempty (oneCellObj.CatchmentBasin)
                    addedbig=false(size(oneCellObj.RequiredImages.ThisCell));
                    x=oneCellObj.RequiredFields.BoundingBox(1);
                    y=oneCellObj.RequiredFields.BoundingBox(2);
                    xLength=oneCellObj.RequiredFields.BoundingBox(3);
                    yLength=oneCellObj.RequiredFields.BoundingBox(4);   
                    
                    addedbig(y:y+yLength-1,x:x+xLength-1)=added;
                    %now add the watershed region (and change name back to added)
                    added=addedbig;
                    added(oneCellObj.RequiredImages.Watershed==0)=1;
                end
                %Fill in the image and open (will remove the extended wsh lines that are not associated with this cell.
                filledScaledImg=imfill(added,'holes');
                filledScaledImg=imopen(filledScaledImg,oneCellObj.RequiredFields.SE);
            else%oneCellObj.DeleteOuter.OuterDeleted is an all black image
                filledScaledImg=oneCellObj.RequiredImages.OuterRemoved;
            end
        end
    end
end