classdef ACCellSerpent<findedges.FindEdges
    methods
        function obj=ACCellSerpent (varargin)
            % ACCellSerpent --- constructor for an object to run the active contour cell serpent method
            %
            % Synopsis:  obj = ACCellSerpent (varargin)
            %                        
            % Output:    obj = object of class ACCellSerpent

            % Notes:                
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.findcentremethod='CentroidsOfBin';%Default value - will calculate the threshold level using the Ostu method.
            
            %Define required fields and images
            obj.requiredImages={'TargetImage'};
            obj.requiredFields={'Centres'};            
            
            %Define user information
            obj.description='Uses active contour method Cell Serpent to find outlines of cells from centre coordinates.';
            obj.paramHelp.FindCentresMethod = 'Parameter ''findcentremethod'': Method used to define cell centres.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use,
            %in the order in which they are called
            obj.Classes(1).classnames=obj.parameters.FindCentresMethod;
            obj.Classes(1).packagenames='findcentres';
            

        end
        
        function paramCheck=checkParams(obj, timelapseObj)
           % checkParams --- checks if the parameters of a Threshold object are in range and of the correct type
           %
           % Synopsis: 	paramCheck = checkParams (obj)
           %
           % Input:	obj = an object of class LoopBasins
           %
           % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

           % Notes:  
           paramCheck='';
           findCentreClasses=obj.listMethodClasses('findcentres');
           if ~any(strcmp(findCentreClasses,obj.parameters.FindCentresMethod));
              paramCheck=[paramCheck 'This parameter must be the name of valid findcentres method.'];
           end
           
           if isempty(paramCheck)
               paramCheck='OK';               
           end            
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the fields and images required for the ACCellSerpent method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class ACCellSerpent
            %            inputObj = an object of a level class.

            % Notes:     Uses a method in the findcentres class to create
            % the inputObj.RequiredFields.Centres field.
            
           fieldHistory=struct('objects', {},'fieldnames',{});
           
           %Create TargetImage field
           inputObj.RequiredImages.TargetImage=inputObj.Target;
           
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for ACCellSerpent, finds cell outlines from centres and input image
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class ACCellSerpent
            %            inputObj = an object carrying the data to be thresholded
            %
            % Output:    inputObj = level object with inputObj.Bin field created or modified

            % Notes:     
            
            fieldHistory=struct('fieldnames',{},'objects',{});
            
             [timepointObj history] = obj.useMethodClassFromRun(inputObj, 'findcentres', obj.parameters.FindCentresMethod, history, varargin);
            
            
            %Code here to find cells using active contour method
            %Write to variable: result.
            
            inputObj.RequiredFields.TempResult=result;
        end
    end
end