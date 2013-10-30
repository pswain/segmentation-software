classdef WshSplit<splitregion.SplitRegionSuperClass
    methods
        function obj=WshSplit(varargin)
            % WshSplit --- constructor for WshSplit, create splitregion object for use of watershed transform to divide region
            %
            % Synopsis:  wshSplitObj = WshSplit()
            %            wshSplitObj = WshSplit(parameters)
            %                        
            % Input:     parameters = cell array in standard matlab input format: {'Parameter1name',parameter1value,'Parameter2name',etc...
            %
            % Output:    wshSplitObj = object of class WshSplit

            % Notes:     This constructor defines the requiredFields
            %            and parameters properties. requiredFields tells
            %            the InitialiseFields method of region classes 
            %            which images must be calculated before this
            %            method can be run. The parameter field can be
            %            input optionally using the Matlab convention of 
            %            the parameter name followed by the value, eg
            %            obj=WshSplit('depth',.5). If no parameter array is
            %            input then the default parameter set will be
            %            constructed. When this class is used in timelapse
            %            segmentation, where defaults are defined in the 
            %            SpecifiedParameters field of a timelapse object,
            %            it should be created with a call to 
            %            timelapse.getobj which will send the appropriate
            %            parameters.
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.depth=.5;               
            
            %Define required fields and images
            obj.requiredImages={'Bin' ; 'DistanceTransform' ; 'LocalMinima'};
            %There are no non-image required fields for this class
               
            %Define user information
            obj.description='Uses the watershed transform to divide an image into basins. Takes a binary input image, applies the distance transform (ie calculates the distance of all white pixels to the nearest black pixel). Then searches for local minima (applying a depth threshold). Then uses the watershed method to find the boundaries between these local minima.';
            obj.paramHelp.depth = 'Parameter ''depth'': Positive number. This is the threshold depth used to define local minima before the watershed is applied. A lower value will result in splitting of the image into more basins. A higher value will reduce the number of basins.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This method does not use any other method or level classes

        end
        function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a WshSplit object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class LoopBasins
            %           timelapseObj = an object of a Timelapse class
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 	

            paramCheck='The parameter depth must be a positive number.';
            
            if isnumeric (obj.parameters.depth)
                if obj.parameters.depth>=0
                    paramCheck='OK';
                end
            end            
        end
          
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Populates the level object fields required to run this method
            %
            % Synopsis:  obj = initializeFields(obj, inputObj)   
            %                        
            % Input:     obj = an object of class LoopBasins
            %            inputObj = an object of a level class
            %
            % Output:    obj = an object of a level class

            % Notes:     Calculates the Bin image if it's not already
            %            present. If the level object that the class works
            %            on is a Region object then the Bin image is copied
            %            from the Timepoint level. During a full timelapse
            %            segmentation using LoopRegions as the Timepoint
            %            segmentation method, the Bin image will have been
            %            created at the timepoint level. When editing such
            %            a timelapse it's important that the Bin image is
            %            created in the same way, so this method calls the
            %            initializeFields method of the Region.Timepoint
            %            object. If the Bin image is not created by this
            %            method then the Huang findregions method is used
            %            to create the Bin image at the region level.
            
            fieldHistory=struct('methodobj', {},'levelobj',{},'fieldnames',{});
            %The bin field may be supplied by a higher level - eg if
            %inputObj is a region object then Bin might be present at
            %the Timepoint level. In that case use the getBw method to
            %copy the relevant part of the timepoint Bin image.
            if ~isfield(inputObj.RequiredImages,'Bin')
            if isa (inputObj, 'Region')               
                %First run the initializeFields method of the
                %timepoint segmentation method - this is likely to
                %create the Bin field of the timepoint object. Then run
                %getBw to create the Bin field of the region.
                if ~isempty (inputObj.Timepoint)
                    if isfield(inputObj.Timepoint.RequiredImages,'Bin')
                        %The initializeFields method of the timepoint
                        %object has created a Bin image. Copy the
                        %relevant part of that to the Region field.
                        inputObj.getBw(inputObj.Timepoint.RequiredImages.Bin);
                    else
                        %The Timepoint doesn't have a Bin image
                        %calculated. Run the initializeFields method of
                        %the Timepoint segmentation method to attempt
                        %to create it. 
                        [inputObj.Timepoint fieldHistory2]=inputObj.Timepoint.SegMethod.initializeFields(inputObj.Timepoint);
                        if ~isempty(fieldHistory2)%a method object has been used by the initializeFields method of the timepoint object
                            fieldIndex=size(fieldHistory,2)+1;
                            fieldHistory(fieldIndex).fieldnames='Timepoint.RequiredImages.Bin';
                            fieldHistory=obj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
                        end
                        
                        if ~isfield(inputObj.Timepoint.RequiredImages,'Bin')
                            %The initializeFields method of the timepoint
                            %segmentation method hasn't created a Bin field. Use a
                            %default findregions method to create it at the region
                            %level.
                            [inputObj fieldHistory] = obj.useMethodClass(inputObj, fieldHistory, 'Bin', 'findregions', 'Huang');
                        else
                            %The initializeFields method of the timepoint
                            %segmentation method has created a bin field.
                            %Use getBw to copy the relevant part of that
                            %image to the region object.
                            inputObj.getBw(inputObj.Timepoint.RequiredImages.Bin);
                        end
                     end                        
                else
                    %There is no timepoint defined for this region -
                    %create the Bin image using a default findregions
                    %method
                    [inputObj fieldHistory] = obj.useMethodClass(inputObj, fieldHistory, 'Bin', 'findregions', 'Huang');
                end
            else
                %The input object is not a region object. In this case
                %use a default findregions method to create the Bin
                %image.
                [inputObj fieldHistory] = useMethodClass(inputObj, fieldHistory, 'Bin', 'findregions', 'Huang');
            end
            end
           
            %Calculate distance transform using bwdist
            if ~isfield(inputObj.RequiredImages,'DistanceTransform')
                bw=1-inputObj.RequiredImages.Bin(:,:,end);
                inputObj.RequiredImages.DistanceTransform=bwdist(bw);
            end
            
            %Calculate local minimum image using imhmin
            if ~isfield(inputObj.RequiredImages,'LocalMinima');
                inputObj.RequiredImages.LocalMinima=imhmin(1-inputObj.RequiredImages.DistanceTransform,obj.parameters.depth);
            end
        end
       
 
                  
                            

        function [inputObj fieldHistory] = run(obj,inputObj)
            % run --- separates region into catchment basins using the watershed transform
            %
            % Synopsis:  regionObj = run (obj, regionObjbj)
            %
            % Input:     obj = an object of class WshSplit
            %            regionObj = an object of a region class
            % Output:    regionObj = an object of a region class

            % Notes:     Separation is based on the binary regionObj.Bw 
            %            image which should give a rough approximtion of
            %            the positions and shapes of cells. The method
            %            looks for local minima of the reciprocal of the
            %            distance transform to begin the search for
            %            watershed lines. The imhmin command takes a depth
            %            threshold parameter which may be input. This
            %            affects the probability of finding a watershed
            %            line - low depth = more lines. Populates the
            %            Region object fields obj.Watershed and
            %            obj.NumBasins.
            fieldHistory=struct('fieldnames',{},'objects',{});                     
            inputObj.RequiredImages.Watershed=watershed(inputObj.RequiredImages.LocalMinima);
            
        end
    end
end
