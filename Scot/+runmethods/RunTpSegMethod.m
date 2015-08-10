classdef RunTpSegMethod<MethodsSuperClass
    
    properties        
        resultImage='Result';
    end
    methods
        function obj = RunTpSegMethod (varargin)
            % RunTpSegMethod --- constructor for RunTpSegMethod, an umbrella function that will call one of the available timepoint segmentation methods
            %
            % Synopsis:      obj = RunTpSegMethod(varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is TpSegMethod.
            %                
            % Output:        obj = object of class RunTpSegMethod

            % Notes: This constructor initialises the parameters, checks
            % them against the defaults stored in
            % Timelapse.SpecifiedParameters and alters them depending on
            % varargin. The help information is displayed when the Timelapse
            % object is selected in the GUI.

            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
            obj.parameters.timepointsegmethod='LoopRegions';%Default timepoint segmentation method. NOTE: If a parameter defines use of another class then it should also be written to obj.Classes, after the call to changeparams.
            obj.paramChoices.timepointsegmethod='timepointsegmethods';

            %Define required fields and images
            %There are no required fields or images for this class

            %Define user information
            obj.description='Timepoint object. Holds the data relating to segmentation of a single timepoint. The parameter ''timepointsegmethod'' specifies the method used to segment the cells of this timepoint.';
            obj.paramHelp.timepointsegmethod = 'Parameter ''timepointsegmethod'': The name of the method used to segment the cells in the timepoint';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use
            obj.Classes.classnames=obj.parameters.timepointsegmethod;
            obj.Classes.packagenames='timepointsegmethods';
            
            
        end

        function paramCheck = checkParams (obj, timelapseObj)
            % checkParams --- checks if the parameters of a RunTpSegMethod object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class RunTpSegMethod
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 
		
            paramCheck='The parameter ''timepointsegmethod'' must be the name of a method in the timepointsegmethods package';
            if ischar(obj.parameters.timepointsegmethod)
                classNames=obj.listMethodClasses('timepointsegmethods');
                if any (strcmp(obj.parameters.timepointsegmethod,classNames))
                    paramCheck='OK';
                end
            end
	  end

        function Timepoint =run(obj,Timepoint, history)
            % run --- run function for RunTpSegMethod, gets an object of the
            %         'TrackMethod' class and initates its run function.
            %
            % Synopsis:  Timepoint = run(obj,Timepoint)
            %                        
            % Input:     obj = an object of the RunTpSegMethod class.
            %            Timepoint = an object of a timepoint class
            %
            % Output:    Timepoint = an object of a timepoint class

            % Notes:     
            
            %Get the segmentation method object.
            if isfield(obj.Classes,'objectnumbers')
               Timepoint.SegMethod=Timepoint.Timelapse.methodFromNumber (obj.Classes.objectnumbers);
            else
               Timepoint.SegMethod = Timepoint.Timelapse.getobj('timepointsegmethods',obj.parameters.timepointsegmethod); %retrieve an object of the class defined by the 'TpSegMethod' parameter
               %Record that this runmethod object calls this class
               obj.Classes.objectnumbers=Timepoint.SegMethod.ObjectNumber;
               Timepoint.Timelapse.setMethodObjField(obj.ObjectNumber, 'Classes', obj.Classes);
            end
            %Save a version of the Timepoint object without images in the
            %Timelapse.LevelObjects structure
            Timepoint.Timelapse.saveLevelObject(Timepoint);            
            %Add this (run) method to the history
            Timepoint.Timelapse.HistorySize=Timepoint.Timelapse.HistorySize+1;
            history.methodobj(Timepoint.Timelapse.HistorySize)=obj.ObjectNumber;
            history.levelobj(Timepoint.Timelapse.HistorySize)=Timepoint.ObjectNumber;
            %Add the segmentation method to the history
            Timepoint.Timelapse.HistorySize=Timepoint.Timelapse.HistorySize+1;
            history.methodobj(Timepoint.Timelapse.HistorySize)=Timepoint.SegMethod.ObjectNumber;
            history.levelobj(Timepoint.Timelapse.HistorySize)=Timepoint.ObjectNumber;
            %Initialize the timepoint object for running its segmentation method     
            [Timepoint fieldHistory]=Timepoint.SegMethod.initializeFields(Timepoint);
            %Add any objects created by the initializeFields call to the
            %history
            for n=1:size(fieldHistory.fieldnames,1)
                [history levelObj]=obj.insertFieldHistory(history, fieldHistory, n, Timepoint);
            end

            %Run the timepoint segmentation method
            Timepoint = Timepoint.SegMethod.run(Timepoint, history);%runs this object to segment the timepoint
            %Remove empty trackingdata entries
            Timepoint.Timelapse.TrackingData(Timepoint.Frame).cells([Timepoint.Timelapse.TrackingData(Timepoint.Frame).cells.trackingnumber]==0)=[];
        end
            
    end
end