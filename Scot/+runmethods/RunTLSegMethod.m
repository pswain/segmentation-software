classdef RunTLSegMethod<MethodsSuperClass
    
    properties
        resultImage='Result';
        numCells=uint8(75);
        numObjects=uint8(20);
    end
    methods
        function obj = RunTLSegMethod (varargin)
            % RunTLSegMethod --- constructor for RunTLSegMethod, an umbrella function that will call one of the available timelapse segmentation methods
            %
            % Synopsis:      obj = RunTLSegMethod(varargin)
            %                        
            % Input:         varargin = parameters given in the conventional matlab format. Only parameter is TpSegMethod.
            %                
            % Output:        obj = object of class RunTLSegMethod

            % Notes: This constructor initialises the parameters, and
            % alters them depending on varargin.
            
            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
            obj.parameters.segmentationmethod='StandardTLseg'; %default value for the only parameter
            obj.paramChoices.segmentationmethod='timelapsesegmethods';
            obj.parameters.filenamecontains='DIC';%String identifying the input images used for segmentation - filenames contain this string - should be one file with the string per timepoint
            obj.parameters.start=1;
            obj.parameters.end=1;%This default value should be redefined in the Timelapse1 constructor
            %There are no required fields or images for this class.
            
            %Define user information
            obj.description='Timelapse. Holds all of the information on segmentation methods and results for a timelapse experiment.';        
            obj.paramHelp.segmentationmethod = 'Parameter ''segmentationmethod'': The name of a method in the timelapsesegmethods package that will be used to segment cells in the timelapse data.';
            obj.paramHelp.filenamecontains='Parameter ''filenamecontains'': This string will be used to identify the image to be used for segmentation at each timepoint. If there are multiple z sections in the channel you want to use, make sure this string identifies the section as well as the channel.';
            obj.paramHelp.start='Parameter ''start'': The timepoint at which segmentation will begin';
            obj.paramHelp.end = 'Parameter ''end'': The timepoint after which segmentation will stop';
            
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use,
            %in the order in which they are called
            obj.Classes.classnames=obj.parameters.segmentationmethod;
            obj.Classes.packagenames='timelapsesegmethods';
            
            %Define fields invisible to the user
            obj.numCells=15;%Estimate of the number of cells present at each timepoint - used for preallocation
            obj.numObjects=20;%Estimate of the number of level objects created in segmentation of each timepoint - used for preallocation

        end
        
        function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a RunTLSegMethod object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class LoopRegions
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

            % Notes: 	

            checked='';
            %obj.parameters.segmentationmethod must be the name of a class in the
            %timelapsesegmethods package
            classNames=obj.listMethodClasses('timelapsesegmethods');
            
            if ~any(strcmp(obj.parameters.segmentationmethod,classNames))
                checked=[checked 'Parameter ''segmentationmethod'' must be the name of a valid class in the ''timelapsesegmethods'' package'];
            end
            
            if strcmp(checked,'')
                paramCheck='OK';
            else
                paramCheck=checked;
            end
        end

        function timelapseObj = run(obj,timelapseObj)
            % run --- run function for RunTLSegMethod, gets an object of the timelapsesegmethod class and initates its run function.
            %
            % Synopsis:  Timelapse = run(obj,Timelapse)
            %                        
            % Input:     obj = an object of the RunTLSegMethod class.
            %            Timelapse = an object of the Timelapse class
            %
            % Output:    Timelapse = an object of the Timelapse class

            % Notes:     
            
            %Start Fiji (used for some image processing functions)
            %First set up the classpath using the Miji script - need to find the
            %directory in which the fiji application directory is located. It is two
            %levels up from the current one.
            if ~exist('MIJ')==8
                thispath=mfilename('fullpath');
                k=strfind(thispath,filesep);
                thatpath=thispath(1:k(end-1));           
                addpath([thatpath 'Fiji.app/scripts']);
                Miji;
            end
            
            %Prepare the timelapse object for segmentation
            [timelapseObj history]=obj.prepareSegmentation (timelapseObj,'Full');            
            
            timelapseObj.StartFrame=obj.parameters.start;
            timelapseObj.EndFrame=obj.parameters.end;
            
            timelapseObj = timelapseObj.SegMethod.run(timelapseObj, history);
%            timelapseObj.RunMethod=setNumCells(timelapseObj.RunMethod, timelapseObj);
        end

    
    
    
        function [timelapseObj history]=prepareSegmentation(obj,timelapseObj, type)
            % prepareSegmentation --- Prepares a timelapse object for running a segmentation
            %
            % Synopsis:  Timelapse = prepareSegmentation (Timelapse)
            %                        
            % Input:     Timelapse = an object of the Timelapse class
            %            type = string, determines type of segmentation being performed
            %            
            %
            % Output:    Timelapse = an object of the Timelapse class

            % Notes:     The actions in this method were removed from the
            %            run method because they also apply when the user
            %            wants to segment a single timepoint. This function
            %            can be called outside the context of running a 
            %            full segmentation. The 'type' input lets the
            %            method know if a full or partial segmentation is
            %            being run - ie if preallocation of memory is
            %            required.
            
            %Start Fiji (used for some image processing functions)
            %First set up the classpath using the Miji script - need to find the
            %directory in which the fiji application directory is located. It is two
            %levels up from the current one.
            if ~exist('MIJ')==8
                thispath=mfilename('fullpath');
                k=strfind(thispath,filesep);
                thatpath=thispath(1:k(end-1));           
                addpath([thatpath 'Fiji.app/scripts']);
                Miji;
            end
                   
            %Pre-allocate the arrays that will be added to during
            %full timelapse segmentation
            if strcmp(type,'Full') || strcmp(type, 'full')
                [timelapseObj history]=timelapseObj.preallocate;
            elseif strcmp(type,'SingleTimepoint')
                %Clear all references in the timelapse to the current
                %timepoint
                timelapseObj.clearFrame(timelapseObj.CurrentFrame);         
            end
            
            %Get the timelapse segmentation method.
            if isfield(timelapseObj.RunMethod.Classes,'objectnumbers')
               timelapseObj.SegMethod=timelapseObj.methodFromNumber (timelapseObj.RunMethod.Classes.objectnumbers);
            else
               timelapseObj.SegMethod = timelapseObj.getobj('timelapsesegmethods',timelapseObj.RunMethod.parameters.segmentationmethod); %retrieve an object of the class defined by the 'TpSegMethod' parameter
               %Record that this runmethod object calls this class
               obj.Classes.objectnumbers=timelapseObj.SegMethod.ObjectNumber;
               timelapseObj.setMethodObjField(obj.ObjectNumber, 'Classes', obj.Classes);
            end
            
            %Record the timelapse in the Timelapse.LevelObjects structure -
            %but only if it's not there already
            record=true;
            if ~isempty(timelapseObj.LevelObjects)
                objNos=[timelapseObj.LevelObjects.ObjectNumber];
                if any(objNos==timelapseObj.ObjectNumber)
                    record=false;
                end
            end
            if record==true
                timelapseObj.saveLevelObject(timelapseObj);
            end
            
            %Create first entry in the history - the timelapse object and
            %this method
            timelapseObj.HistorySize=1;
            history.levelobj(timelapseObj.HistorySize)=timelapseObj.ObjectNumber;
            history.methodobj(timelapseObj.HistorySize)=timelapseObj.RunMethod.ObjectNumber;
            %Add the timelapse segmentation method to the history
            timelapseObj.HistorySize=timelapseObj.HistorySize+1;
            history.methodobj(timelapseObj.HistorySize)=timelapseObj.SegMethod.ObjectNumber;
            history.levelobj(timelapseObj.HistorySize)=timelapseObj.ObjectNumber;           
        end
    end
        
        methods (Static)
        function obj=setNumCells (obj, timelapseObj)
            % setNumCells --- Defines the obj.numCells property as the highest number of cells yet segmented at any timepoint
            %
            % Synopsis:  obj = setNumCells (obj, timelapseObj)
            %                        
            % Input:     obj = an object of class RunTLSegMethod
            %            timelapseIbj = an object of a Timelapse class
            %
            % Output:    obj = an object of class RunTLSegMethod

            % Notes:     The numCells property is used in preallocation.
            %            This method should be run to keep the value up to 
            %            date after a timelapse or single timepoint
            %            segmentation.
            
            if size(timelapseObj.TrackingData,2)>0
                %Get number of cells in the frame with most cells segmented
                number=uint8(max(timelapseObj.LevelObjects.TrackingNumber));

                obj.numCells=number;
            end
        end
            
    end
end