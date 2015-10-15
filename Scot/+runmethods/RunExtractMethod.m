classdef RunExtractMethod<MethodsSuperClass
   properties
        resultImage='Result';
   end
    methods
        function obj = RunExtractMethod(varargin)
            % RunExtractMethod --- constructor for RunExtractMethod, an umbrella function that will call one of the available data extraction methods
            %
            % Synopsis:      obj = RunExtractMethod(varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is TrackMethod.
            %                
            % Output:        obj = object of class RunExtractMethod

            % Notes: This constructor initialises the parameters, checks
            % them against the defaults stored in
            % Timelapse.SpecifiedParameters and alters them depending on
            % varargin.
                      
            obj.parameters = struct ('datafields',{'GFP MeanFluorescence'}); %default value for the only parameter. This can be a cell array of strings. The extractdata methods with these datafields will be run
            obj=obj.changeparams(varargin{:});
   
        end

        function [Timelapse history] =run(obj,Timelapse)
            % run --- run function for RunExtractMethod, gets an object of the
            %         'ExtractMethod' class and initates its run function.
            %
            % Synopsis:  Timelapse = run(obj,Timelapse)
            %                        
            % Input:     obj = an object of the RunTrackMethod class.
            %            Timelapse = an object of the Timelapse class
            %
            % Output:    Timelapse = an object of the Timelapse class

            % Notes:     Unlike other run methods this one can only run
            %            methods that are already stored in the 
            %            timelapse.ObjectStruct property. This is necessary
            %            to avoid having to load all parameters into this
            %            object.
            
            
            if ~isempty(obj.parameters.datafields) && ~isempty(fields(Timelapse.ObjectStruct.extractdata))%Only do anything if there is at least one datafield specified and there are extractdata objects
                for n=1:size(obj.parameters.datafields,1)%loop through the extractdata methods defined by the datafields parameter
                    objectTypes=fields(Timelapse.ObjectStruct.extractdata);%The types of the available methods
                    %Check if an object exists with the defined datafield
                    for t=1:size(objectTypes,1)%Loop through the object types
                        objectType=objectTypes{t};
                        for o=1:size([Timelapse.ObjectStruct.extractdata.(objectType)],2);
                            if strcmp(Timelapse.ObjectStruct(t).extractdata(o).(objectType).datafield,obj.parameters.datafields{n})
                            %This is a method to use
                            Timelapse = Timelapse.ObjectStruct(t).extractdata(o).(objectType).run(Timelapse);%runs this object to extract data
                            %Now add the data extraction method to the posthistory
                            %- but only if it's not there already with the same
                            %parameters
                            Timelapse.PostHistory(size(Timelapse.PostHistory,2)+1)=Timelapse.ObjectStruct(t).extractdata(o).(objectType).ObjectNumber;
                            end
                        end                        
                    end                     
                end
            end
        end
            
    end
    
    
    
    
    
end