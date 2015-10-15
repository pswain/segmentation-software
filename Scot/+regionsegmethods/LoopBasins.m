classdef LoopBasins<regionsegmethods.RegSegmethods
    methods
        function obj=LoopBasins(varargin)
               % LoopBasins --- constructor for LoopBasins
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
               
               %Define required fields and images
               obj.requiredImages={'Bin';'Watershed'};
               obj.requiredFields={'NumBasins'};
               
                              
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
               obj.Classes(2).classnames='OneCell';
               obj.Classes(2).packagenames='Level';
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
            splitRegionsNames=obj.listMethodClasses('splitregions');
            
            if ~any(strcmp(obj.parameters.splitregions,splitRegionsNames))
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
            
            %Now create the 'Watershed' field by applying a splitregions
            %method to the Bin image.
            if ~isfield (regionObj.RequiredImages,'Watershed') 
                [regionObj fieldHistory]=obj.useMethodClass(obj,regionObj, fieldHistory, 'Watershed', 'splitregion', obj.parameters.splitregion);
            end
            
            %After the watershed image is created can define the NumBasins
            %field - no if statement here - need to define the filed on the
            %basis of the watershed image even if an entry already exists.
            
            regionObj.RequiredFields.NumBasins=max(regionObj.RequiredImages.Watershed(:));
            
        end
            
            
        
        function regionObj=run(obj, regionObj,history)
            % run --- run function for LoopBasins, segments a region by splitting it, then looping through each catchment basin, looking for a cell in each one.
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
            %            
            if max(regionObj.RequiredImages.Watershed(:))>1%the region has been split by the watershed
                regionObj.Result=false(size(regionObj.Target,1),size(regionObj.Target,2),regionObj.NumBasins);%initialise result stack - initially one slice for each catchment basin
                numCells=0;
                for n=1:regionObj.RequiredFields.NumBasins%loop through the catchment basins
                    historySize=regionObj.Timelapse.HistorySize;
                    showMessage(strcat('catchment',num2str(n)));%comment for speed
                    newCell=OneCell3(regionObj, n, history);
                    regionObj.Timelapse.HistorySize=historySize;
                end
                regionObj.Result(:,:,numCells+1:end)=[];%remove empty slices (where segmentation has failed)
            else%there is only one cell in this region. Has not been split.
                newCell=OneCell3(regionObj, 0, history);
            end
            

            
                        
        end
    end    
end