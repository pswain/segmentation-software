classdef Segmethod_6<cellsegmethods.EdgeSuperClass   
    methods
        function obj=Segmethod_6(varargin)
            % Segmethod_6 --- constructor for Segmethod_6, initialises cellsegmethods object for: erode convex hull of outer edge object
            %
            % Synopsis:  Segmethod_6obj = Segmethod_6()
            %            Segmethod_6obj = Segmethod_6(parameters)

            %                        
            % Input:     parameters = holding the object parameters in standard Matlab input format
            %
            % Output:    Segmethod_6obj = object of class Segmethod_6

            % Notes:	 This constructor creates and parameterizes an
            %            object of class Segmethod_6. Parameter values are 
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
            obj.parameters.ErodeTarget=0.5;
            obj.parameters.disksize=2;

            %Define required fields and images
            %Note: This method class shares certain required fields with other classes
            %based on edge-detection methods. The initializeFields method is therefore
            %also shared, in the EdgeSuperClass.      
            obj.requiredImages={'EdgeImage';'OuterRemoved'; 'OuterImage'; 'ThisCell'};
            obj.requiredFields={'SE';  'BoundingBox'};
		
            %Define user information
            obj.description='Edge-based segmentation method 6. One of several related methods for Saccharomyces cells, that use Canny edge detection to create an image with an outer edge (representing the cell wall-medium boundary) and an inner edge, representing the boundary between the cytoplasm and the cell wall. The aim is to create an object bounded by this inner edge. Canny edge detection is applied to the target image. The outermost connected object in the edge image is approximately the same shape as the cell. The convex hull is created of this outermost edge image then eroded progressively until a defined proportion (the parameter erodetarget) of the remaining edge pixels is uncovered by the erosion.';        
            obj.paramHelp.disksize = 'Parameter ''disksize'': The radius of the (disk-shaped) structuring element used in image opening. A larger value will cause smaller features in the image to be ignored by the image opening operation. A value too large will remove cells.';
            obj.paramHelp.ErodeTarget='Parameters ''ErodeTarget'': Proportion of inner edge pixels that should be uncovered before erosion stops.';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

            %This class does not use any other classes. obj.Classes is left empty.
            

        end

	  function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Segmethod_6 object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class Segmethod_6
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes:
            paramCheck=''; 
            if ~isnumeric(obj.parameters.disksize)
                paramCheck='Parameter ''disksize'' must be a number';
            elseif obj.parameters.disksize>timelapseObj.ImageSize(1)/3
                paramCheck='disksize too large. Choose a number significantly smaller than the image size.';
            end

            if ~isnumeric(obj.parameters.erodetarget)
                paramCheck=[paramCheck 'Parameter ''erodetarget'' must be a number'];
            elseif obj.parameters.erodetarget>1 || obj.parameters.erodetarget<=0
                paramCheck=[paramCheck 'Parameter ''erodetarget'' must be a number between 0 and 1'];
            end

            if paramCheck=='';
                paramCheck='OK';
            end
	  end

        function [oneCellObj]=run(obj, oneCellObj)
            % run --- run function for Segmethod_6, creates result for erode convex hull segmentation method 
            %
            % Synopsis:  oneCellObj = run(obj, oneCellObj)
            %                        
            % Input:     obj = an object of class Segmethod_6
            %            oneCellObj = an object of a OneCell class
            %
            % Output:    oneCellObj = an object of a OneCell class, shows segmentation result in .Result field
            % 
            % Notes:
            oneCellObj.Result=obj.erodeConvexHull(oneCellObj);
            if any(oneCellObj.Result(:))
                oneCellObj.Result=imopen(oneCellObj.Result,oneCellObj.RequiredFields.SE);
            end
        end
   
   
        function eroded=erodeConvexHull(obj,oneCellObj)
            % erodeConvexHull --- Performs segmentation by creating the convex hull of all edge pixels and eroding until a target proportion of inner edge pixels have been uncovered
            %
            % Synopsis:  eroded = erodeConvexHull(oneCellObj)
            %                        
            % Input:     oneCellObj = an object of a OneCell class
            %                        
            % Output:    erode = 2d logical matrix, shows segmentation result

            % Notes: Canny edge detection on DIC images of yeast normally
            % detects two roughly parallel edges, representing the
            % junctions between the cell interior and the cell wall and the
            % cell wall and the medium. This method assmumes that the
            % outermost and second outermost objects in the edge image
            % represent approximately these junctions. First an object is
            % created  having approximately the same shape as the cell but
            % larger, the size being determined by the outermost contiguous
            % object in the edge image. This convex hull object is then
            % iteratively eroded until a given proportion of pixels of the
            % second outermost edge object is uncovered (ie until the
            % erosion has reached the cell wall-cytoplasm junction.             
            propsOuter=regionprops(oneCellObj.RequiredImages.OuterImage,'ConvexImage','BoundingBox','Area');
            props=regionprops(oneCellObj.RequiredImages.OuterRemoved);
            if size(propsOuter,1)>0 && size(props,1)>0;%make sure there is something in both OuterImage and in OuterRemoved
                %Make convex hull image and place in an image field of the
                %correct dimensions
                convexHull=propsOuter(1).ConvexImage;
                score=0;
                eroded=false(size(oneCellObj.RequiredImages.EdgeImage));
                boxs=vertcat(propsOuter.BoundingBox);
                topleftx=ceil(boxs(1,1));
                toplefty=ceil(boxs(1,2));  
                lengthx=boxs(1,3)-1;
                lengthy=boxs(1,4)-1;
                eroded(toplefty:toplefty+lengthy,topleftx:topleftx+lengthx)=convexHull;
                %Now define when to stop - how many edge pixels should be 
                %removed by the erosion before stopping.
                
                %Starting point is the number of white pixels in the original outer
                %object
                outerEdge=sum(oneCellObj.RequiredImages.OuterRemoved(:));


                %now find the size of the 2nd closest object to the periphery
                [closest outerimage meandist]=cellsegmethods.FindOuter.furthestFromCentroid(oneCellObj.RequiredImages.OuterRemoved,oneCellObj.RequiredImages.ThisCell);
                

                props=regionprops(oneCellObj.RequiredImages.OuterRemoved);
                inneredge=props(closest).Area;%this is now the size in pixels of the 2nd outermost object in EdgeImage
                
                %stop eroding when you have uncovered >= the target proportion of pixels in the 2nd
                %closest object to the periphery

                target=outerEdge+inneredge.*obj.parameters.ErodeTarget;

                %to avoid possible endless loops need to check that the convex hull
                %actualy contains enough edge pixels to get to the target
                testimage=eroded;
                testimage(oneCellObj.RequiredImages.EdgeImage==1)=0;
                numedgeinconvhull=nnz(eroded)-nnz(testimage);%number of edge pixels in the convex hull

                    if numedgeinconvhull>target

                         while score<=target;%keep eroding until you uncover this number of edge pixels
                         %disp(strcat('score=',num2str(score)));
                         eroded= bwmorph(eroded,'skel',1);
                         eroded=bwmorph(eroded,'spur');
                         testimage=oneCellObj.RequiredImages.EdgeImage-eroded;
                         uncoveredpixels=find (testimage>0);
                         score=size(uncoveredpixels,1);
                         end

                    else
                        %disp('Endless loop avoided - number of edge pixels in convex hull was <=target');

                    end
             %Now make the result image the same size as the Target image if the cell is split
    %             if isempty (obj.SmallWatershed)==0;
    %                 result=false(size(obj.ThisCell));
    %                 result(obj.TopLeftThisCelly:obj.TopLeftThisCelly+obj.yThisCellLength-1,obj.TopLeftThisCellx:obj.TopLeftThisCellx+obj.xThisCellLength-1)=eroded;
    %                 eroded=result;%change name back - for returning the image
    %             end


            else%outerimage is empty - just return an empty image
             eroded=false(size(oneCellObj.RequiredImages.OuterRemoved));
            end

        
        end%of erodeconvexhull function
    
    end
end