classdef RunRegionSegMethod<MethodsSuperClass
    
    properties
        resultImage='Result';
    end
    
    methods
        function obj = RunRegionSegMethod (varargin)
            % RunRegionSegMethod --- constructor for RunRegionSegMethod, an umbrella function that will call one of the available region segmentation methods
            %
            % Synopsis:      obj = RunRegionSegMethod(varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is TpSegMethod.
            %                
            % Output:        obj = object of class RunRegionSegMethod

            % Notes: This constructor initialises the parameters, checks
            % them against the defaults stored in
            % Timelapse.SpecifiedParameters and alters them depending on
            % varargin.
            
            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
            obj.parameters.regionsegmethod='LoopBasins';%Default region segmentation method. NOTE: If a parameter defines use of another class then it should also be written to obj.Classes, after the call to changeparams.
            obj.paramChoices.regionsegmethod='regionsegmethods';
            %Defining a paramchoices entry for this parameter specifies that there are a limited number of parameter values - to be selected from a drop down list.
            %In this case the possible values are the names of classes in the regionsegmethods package
            
            %Define required fields and images
            %There are no required fields or images for this class

            %Define user information
            obj.description='Region object. Holds the data relating to segmentation of a single region. The parameter ''regionsegmethod'' specifies the method used to segment the cells in this region.';
            obj.paramHelp.regionsegmethod = 'Parameter ''regionsegmethods'': The name of the method that will be used to segment the region';

            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use
            obj.Classes.packagenames='regionsegmethods';
            obj.Classes.classnames=obj.parameters.regionsegmethod;
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
		
            paramCheck='The parameter ''regionsegmethods'' must be the name of a method in the regionsegmethods package';
            if ischar(obj.parameters.regionsegmethod)
                classNames=obj.listMethodClasses('regionsegmethods');
                if any (strcmp(obj.parameters.regionsegmethod,classNames))
                    paramCheck='OK';
                end
            end
        end


        function regionObj =run(obj,regionObj, history)
            % run --- run function for RunRegionSegMethod, gets an object of a class in the regionsegmethods package and runs it
            %
            % Synopsis:  regionObj = run(obj, regionObj)
            %                        
            % Input:     obj = an object of the RunTrackMethod class.
            %            regionObj = an object of a region class
            %
            % Output:    regionObj = an object of a region class
 
            % Notes:
            if isfield(obj.Classes,'objectnumbers')
               regionObj.SegMethod=regionObj.Timelapse.methodFromNumber (obj.Classes.objectnumbers);
            else
               regionObj.SegMethod = regionObj.Timelapse.getobj('regionsegmethods',obj.parameters.regionsegmethod); %retrieve an object of the class defined by the 'TpSegMethod' parameter
               %Record that this runmethod object calls this class
               obj.Classes.objectnumbers=regionObj.SegMethod.ObjectNumber;
               regionObj.Timelapse.setMethodObjField(obj.ObjectNumber, 'Classes', obj.Classes);
            end

            %Add this (run) method to the history
            regionObj.Timelapse.HistorySize=regionObj.Timelapse.HistorySize+1;
            history.methodobj(regionObj.Timelapse.HistorySize)=obj.ObjectNumber;
            history.levelobj(regionObj.Timelapse.HistorySize)=regionObj.ObjectNumber;
            %Add the segmentation method to the history
            regionObj.Timelapse.HistorySize=regionObj.Timelapse.HistorySize+1;
            history.methodobj(regionObj.Timelapse.HistorySize)=regionObj.SegMethod.ObjectNumber;
            history.levelobj(regionObj.Timelapse.HistorySize)=regionObj.ObjectNumber;
            %Initialize the region object for running its segmentation
            %method
            [regionObj fieldHistory]=regionObj.SegMethod.initializeFields(regionObj);
            %Add any objects created by the initializeFields call to the
            %history
            for n=1:size(fieldHistory.fieldnames,1)
                [history regionObj]=regionObj.SegMethod.insertFieldHistory(history, fieldHistory, n,regionObj);
            end
            %Run the segmentation
            regionObj= regionObj.SegMethod.run(regionObj, history);
            %Save a version of the region object without images in the
            %Timelapse.LevelObjects structure
            regionObj.Timelapse.saveLevelObject(regionObj);
        end
            
    end
end