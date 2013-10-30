classdef RunSplitRegionMethod<MethodsSuperClass
    
    properties
        resultImage='Result';
    end
    methods
        function obj = RunSplitRegionMethod (varargin)
            % RunSplitRegionMethod --- constructor for RunSplitRegionMethod, an umbrella function that will call one of the available splitregion methods
            %
            % Synopsis:      obj = RunSplitRegionMethod (varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is SplitRegionMethod.
            %                
            % Output:        obj = object of class RunSplitRegionMethod

            % Notes: This constructor initialises the parameters, checks
            % them against the defaults stored in
            % Timelapse.SpecifiedParameters and alters them depending on
            % varargin.
                      
            obj.parameters = struct ('splitregion','WshSplit'); %default value for the only parameter
            obj=obj.changeparams(varargin{:});   
        end

        function [regionObj history]=run(obj,regionObj, timepointObj, history)
            % run --- run function for RunSplitRegionMethod, gets an object 
            %         of the appropriate splitregion class and initates its  
            %         run function.
            %
            % Synopsis:  regionObj =run (obj, regionObj, timepointObj)
            %                        
            % Input:     obj = an object of class RunSplitRegionMethod
            %            regionObj = an object of a region class
            %            timepointObj = an object of a timepoint class
            %
            % Output:    regionObj = an object of a region class

            % Notes:     Modifies the region object by running one of the
            %            split region methods - will populate the watershed
            %            and NumBasins fields of the region object.
            
            method = timepointObj.Timelapse.getobj('splitregion',obj.parameters.splitregion); %retrieve an object of the class defined by the 'SplitRegionMethod' parameter
            method.initializeFields(regionObj);%populate the required fields of the region object (if any)
            [regionObj history] = method.run(regionObj, history);%runs this object to segment the timepoint
        end     
    end
end