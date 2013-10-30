classdef RunTrackMethod<MethodsSuperClass
    
    properties
        resultImage='Result';
    end
    methods
        function obj = RunTrackMethod(varargin)
            % RunTrackMethod --- constructor for RunTrackMethod, an umbrella function that will call one of the available tracking methods
            %
            % Synopsis:      obj = RunTrackMethod(varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is TrackMethod.
            %                
            % Output:        obj = object of class RunTrackMethod

            % Notes: This constructor initialises the parameters, checks
            % them against the defaults stored in
            % Timelapse.SpecifiedParameters and alters them depending on
            % varargin.
                      
            obj.parameters = struct ('trackmethods','loop_timepoints'); %default value for the only parameter
            obj=obj.changeparams(varargin{:});
   
        end

        function [Timelapse history] =run(obj,Timelapse)
            % run --- run function for RunTrackMethod, gets an object of the
            %         'TrackMethod' class and initates its run function.
            %
            % Synopsis:  Timelapse = run(obj,Timelapse)
            %                        
            % Input:     obj = an object of the RunTrackMethod class.
            %            Timelapse = an object of the Timelapse class
            %
            % Output:    Timelapse = an object of the Timelapse class

            % Notes:     
            
            method = Timelapse.getobj('trackmethods',obj.parameters.trackmethods); %retrieve an object of the class defined by the 'TrackMethod' parameter
            Timelapse = method.run(Timelapse);%runs this object to track the Timelapse object
            Timelapse.addToPostHistory(method);
        end
            
    end
end