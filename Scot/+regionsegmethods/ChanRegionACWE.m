classdef ChanRegionACWE<regionsegmethods.RegSegmethods
    properties
    SE
    end
    methods
        function obj=ChanRegionACWE(varargin)
               % LoopBasins --- constructor for ChanRegionACWE
               %
               % Synopsis:  obj = LoopBasins()
               %            obj = LoopBasins(varargin)
               %                        
               % Input:     varargin = holding the object parameters in standard Matlab input format
               %
               % Output:    obj = object of class LoopBasins

               % Notes:     This constructor defines the requiredFields
               %            and parameters properties. requiredFields tells
               %            the InitialiseFields method of onecell classes 
               %            which images must be calculated before this
               %            method can be run. The parameter field can be
               %            input optionally using the Matlab convention of 
               %            the parameter name followed by the value. If no
               %            parameter array is input then the default
               %            parameter set will be constructed.  When this  
               %            class is used in timelapse segmentation, where 
               %            defaults are defined in the SpecifiedParameters 
               %            field of a timelapse object, it should be 
               %            created with a call to timelapse.getobj which 
               %            will send the appropriate parameters.
               
               %Create obj.parameters structure and define default parameter value          
               obj.parameters = struct();
               obj.parameters.splitregion='WshSplit';%Default region splitting method. NOTE: If a parameter defines use of another class then the contents need to be copied to the obj.Classes property (after the call to changeparams).
               obj.parameters.mu=0.1;%mu: the length term of equation(9) in ref[1] (see acew.m)
               obj.parameters.v=0.1;%v: the area term of eq(9)
               obj.parameters.epsilon=1;%epsilon: the parameter to avoid 0 denominator
               obj.parameters.timestep=0.1;%timestep: the descenting step each time(positive real number)
               obj.parameters.lambda1=1;%lambda1, lambda2: the data fitting term
               obj.parameters.lambda2=1;
               obj.parameters.iterations=200;%numIter: the number of iterations
               obj.parameters.pc=1;%pc: the penalty coefficient(used to avoid reinitialization according to [2])

               





               
               %Define required fields and images
               obj.requiredImages={'Bin';'ContourResult';'Watershed';'level_set_function'};
               obj.requiredFields={'NumBasins';'SE'};
               
                              
               %Define user information
               obj.description='Region segmentation method, LoopBasins. Uses a split region method to create a Watershed image. Then loops through the catchment basins of this image, calling the OneCell3 constructor to attempt to segment a cell in each one.';
               obj.paramHelp.splitregion = 'Parameter ''splitregions'': The name of a method in the splitregions package that will be used to divide the region into ''catchment basins'', each of which contains one cell.';
               
               %Call changeparams to redefine parameters if there are input arguments to this constructor              
               obj=obj.changeparams(varargin{:});
               
               %List the method and level classes that this method will use
               %This will allow the GUI to parameterize these classes
               %before this method is run
               obj.Classes(1).classnames=obj.parameters.splitregion;
               obj.Classes(1).packagenames='splitregion';
               %obj.Classes(2).classnames='OneCell';
               %obj.Classes(2).packagenames='Level';
               
               obj.SE=strel('Disk',2);
        end
        
        function paramCheck=checkParams (obj, timelapseObj)
            % checkParams --- checks if the parameters of a LoopBasins object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class LoopBasins
            %           timelapseObj = an object of a Timelapse class
            %
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 	

            checked='';
            %obj.parameters.splitregion must be the name of a class in the
            %splitregions package
            splitRegionsNames=obj.listMethodClasses('splitregion');
            
            if ~any(strcmp(obj.parameters.splitregion,splitRegionsNames))
                checked=[checked 'Parameter ''splitregions'' must be the name of a valid class in the ''splitregions'' package'];
            end                      
            
            if strcmp(checked,'')
                paramCheck='OK';
            else
                paramCheck=checked;
            end
        end
        
        
        function [regionObj fieldHistory]=initializeFields(obj, regionObj)
            % initializeFields --- Populates the region fields required to run this method
            %
            % Synopsis:  obj = initializeFields(obj, regionObj)   
            %                        
            % Input:     obj = an object of class LoopBasins
            %            regionObj = an object of a region class
            %
            % Output:    obj = an object of a region class

            % Notes:     Calculates images and other fields as required by
            %            the LoopBasins method. Writes required images to
            %            regionObj.RequiredImages. Avoids unnecessary 
            %            calculations by first checking if each field has             
            %            already been created.
            
            %Initialize the field history as an empty structure
            fieldHistory=struct('methodobj', {},'levelobj',{},'fieldnames',{});                
            
            %The 'Bin' field is used by the code that creates the 'Watershed'
            %field. Therefore the 'Bin' field must be created first.
            
            %Create the Bin image - a binary image containing an approximation to the positions of cells in the region
            if ~isfield (regionObj.RequiredImages,'Bin')
                %If the bin image is created at the timepoint level then it
                %is copied from the timepoint object. Run the
                %initializeFields method of the timepoint segmentation
                %method to create it if it isn't already present.
                [regionObj.Timepoint fieldHistory2]=regionObj.Timepoint.SegMethod.initializeFields(regionObj.Timepoint);
                if ~isempty(fieldHistory2)%a method object has been used by the initializeFields method of the region object
                    fieldIndex=1;%this is the first entry in the field history for this method
                    fieldHistory(fieldIndex).fieldnames='Bin';
                    fieldHistory=obj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
                end
                %If Bin is now present at the timepoint level then call the
                %getBw method - this copies the appropriate region of the
                %timepoint level Bin image to the region object.
                if isfield(regionObj.Timepoint.RequiredImages,'Bin');
                    regionObj.getBw(regionObj.Timepoint.RequiredImages.Bin);
                else
                    %The timepoint segmentation method does not create a
                    %Bin image in its initializeFields method. In this case
                    %use a default findregions method to create it at this
                    %level.
                    [regionObj fieldHistory]=obj.useMethodClass(obj, regionObj, fieldHistory, 'Bin', 'findregions', 'Huang');   
                end
            end
            
            
            
            %rescale target image to 0 - 25 as expected by acwe code (made
            %for 8bit images)
            target_image = double(regionObj.Target);
            target_image = 250*double((target_image-min(target_image(:)))/(max(target_image(:))-min(target_image(:))));
            
            %meshgrids used by inpolygon
            [X,Y] = meshgrid(1:size(target_image,2),1:size(target_image,1));
            
            %smooth image for less bumpy contour
            target_image = medfilt2(target_image, [5, 5]);
            
            %give a square as the initial contour (everything
            %inside the initial contour is set to 2)

            contourResult = 2*ones(size(target_image));
            contourResult((2+floor(size(contourResult,1)/5)):(end-ceil(size(contourResult,1)/5)),...
                (2+floor(size(contourResult,2)/5)):(end-ceil(size(contourResult,2)/5))) = -2;
            
            
            %Now apply the chan-vese active contour method to the main
            %target image, using the bin image as a mask. This will refine
            %the bin image result.
            %The particular implementation of the chanvese is called
            %acwe.m. It was downloaded from the file exchange:
            %http://www.mathworks.co.uk/matlabcentral/fileexchange/34548-active-contour-without-edge
            %and written by Su Dongcai
            %it applies a gradient descent method to minise the chan vese
            %cost function.
            
            
            
            for n=1:obj.parameters.iterations
                contourResult=acwe(contourResult, target_image,  obj.parameters.timestep,...
                    obj.parameters.mu, obj.parameters.v, obj.parameters.lambda1, obj.parameters.lambda2, obj.parameters.pc, obj.parameters.epsilon, 1);
                
            end
            
            %go through each individual contour and draw a polygon for them
            contourResult = padarray(contourResult,[2 2],1);   
            %Preceed this with an if statement - whether to display
            %segmentation in progress or not
            
            c = contour(contourResult,[0,0],'r');
            index = find(c(1,:)==0);
            index = [index length(c)];
            c = c-2;
            
            imres = false(size(target_image));
            
            for i=1:(size(index,2)-1)       
                imres = imres | inpolygon(X,Y,c(1,(index(i)+1):(index(i+1)-1))',c(2,(index(i)+1):(index(i+1)-1))');
            end
            
            
            regionObj.RequiredImages.level_set_function=contourResult(3:(end-2),3:(end-2));
            
            regionObj.RequiredImages.ContourResult=imres;
                       
            if ~isfield (regionObj.RequiredImages,'Watershed') 
                [regionObj fieldHistory]=obj.useMethodClass(obj,regionObj, fieldHistory, 'Watershed', 'splitregion', obj.parameters.splitregion);
            end
            
            %After the watershed image is created can define the NumBasins
            %field - no if statement here - need to define the filed on the
            %basis of the watershed image even if an entry already exists.
            
            regionObj.RequiredFields.NumBasins=max(regionObj.RequiredImages.Watershed(:));
            
        end
            
            
        
        function regionObj=run(obj, regionObj,history)
            % run --- run function for ChanRegion, segments a region by splitting it, then looping through each catchment basin, looking for a cell in each one.
            %
            % Synopsis:  oneCellObj = run(obj, regionObj)
            %                        
            % Input:     obj = an object of class LoopBasins
            %            regionObj = an object of a region class
            %
            % Output:    regionObj = an object of a region class

            % Notes:     Populates the NumBasins, Watershed, Result and 
            %            Target fields of the region object and some
            %            others, depending on the methods used to split and
            %            segment the region.        
            
            %Set the watershed lines to zero in the binary result image
            resultImage=regionObj.RequiredImages.Bin(:,:,end);
            resultImage(regionObj.RequiredImages.Watershed==0)=0;           
            
            %Apply image opening to remove spurs and isolated pixels
            resultImage=imopen(resultImage,obj.SE);
            
            %Record the result image stack
            props=regionprops(resultImage,'Image', 'BoundingBox');
            regionObj.Result=false(size(resultImage,1), size(resultImage,2), size(props,1));
            for n=1:size(props,1)
                x=ceil(props(n).BoundingBox(1));
                y=ceil(props(n).BoundingBox(2));
                regionObj.Result(y:y+props(n).BoundingBox(4)-1,x:x+props(n).BoundingBox(3)-1,n)=props(n).Image;
            end
            %Record results at the timelapse level
            regionObj=obj.recordCells(regionObj, history);

            
           
            

            
                        
        end
    end    
end