classdef LoadCentres<findcentres.FindCentres
    methods
        function obj=LoadCentres (varargin)
            % LoadCentres --- constructor for an object to load centroid positions from a saved version of the current timelapse
            %
            % Synopsis:  obj = LoadCentres (varargin)
            %                        
            % Output:    obj = object of class LoadCentres

            % Notes:                
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.savedtimelapse='/Users/iclark/Documents/Microscopy data/NikonTi after Aug2010/Ivan/RAW DATA/2013/Apr/24-Apr-2013//pos1.sct';

            %There are no required fields or images for this class
            
            %Define user information
            obj.description='Loads centroid positions from a saved timelapse';
            obj.paramHelp.savedtimelapse = 'Parameter ''savedtimelapse'': full path to the saved timelapse having centroid information';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use


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
           paramCheck='OK';               
                    
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the fields and images required for the CentroidsOfBin method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class CentroidsOfBin
            %            inputObj = an object of a level class.

            % Notes:     Uses a method in the findcentres class to create
            % the inputObj.RequiredFields.Centres field.
            
           fieldHistory=struct('objects', {},'fieldnames',{});
           
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for LoadCentres
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class LoadCentres
            %            inputObj = an object carrying the data to be operated on
            %
            % Output:    inputObj = level object with inputObj.RequiredFields.Centres created or modified

            % Notes:     
            
            fieldHistory=struct('fieldnames',{},'objects',{});
            tl=Timelapse1.loadTimelapse(obj.parameters.savedtimelapse);
            %Then the centres
            inputObj.RequiredFields.Centres(:,1)=[tl.TrackingData(inputObj.Frame).cells.centroidx];
            inputObj.RequiredFields.Centres(:,2)=[tl.TrackingData(inputObj.Frame).cells.centroidy];
            
          
        end
    end
end