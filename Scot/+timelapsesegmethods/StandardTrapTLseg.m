classdef StandardTrapTLseg<timelapsesegmethods.TimelapseSegMethodsSuperClass
    methods
        function obj=StandardTrapTLseg(varargin)
            % StandardTLseg --- constructor for StandardTLseg class for timelapse segmentation
            %                                
            % Synopsis:           obj = StandardTLseg(varargin)
            %
            % Input:              varargin = parameters in standard Matlab format
            % 
            % Output:             obj = object of class StandardTLseg
            %                    
            
            %Notes:
            
            
            %Create obj.parameters structure and define default parameter values
            obj.parameters = struct;
                        
            %There are no required fields or images for this method
            
            %Define user information
            obj.description='StandardTrapTLSeg. Standard timelapse segmentation method. Runs through each timepoint in order, creating a new Timepoint object for each. Segmentation is performed at lower levels.';        

            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use,
            %in the order in which they are called
%             obj.Classes(1).classnames='Timepoint';
%             obj.Classes(1).packagenames='Level';                       
           
        end
       
        function [timelapseObj]=run(obj, timelapseObj, history)
            % run ---  performs timelapse segmentation
            %
            % Synopsis:  timelapseObj = (obj, timelapseObj, history)
            %                        
            % Input:     obj = an object of the StandardTLSeg class.
            %            timelapseObj = an object of a Timelapse class
            %            history = structure, contains details of objects used so far in timelapse segmentation
            %
            % Output:    timelapseObj = an object of a Timelapse class

            % Notes: This method performs timelapse segmentation by
            %        looping through the timepoints, calling the
            %        Timepoint3 constructor to create a timepoint
            %        object for each one. The returned object, timelapseObj
            %        is a handle object and is modified during the call to
            %        segmentOneTimepoint (and Timepoint3).
            
            %Loop through the timepoints calling the constructor of
            %Timepoint3, which segments cells.
            cTimelapse=timelapseTraps('b');

            cTimelapse.loadTimelapseScot(timelapseObj);
            load('CellVisionModel');
            uiwait();
            
            cTrapSelectDisplay(cTimelapse,cCellVision)
            
            uiwait()
            
            %
            cCellVision.twoStageThresh=0;
            method='twostage';
            cTrapDisplayProcessing(cTimelapse,cCellVision,method);
            
            

            
        end
        
        function timepointObj = segmentOneTimepoint (obj, timelapseObj, history)
            % segmentOneTimepoint ---  segments a single timepoint by creating a Timepoint3 object
            %
            % Synopsis:  timepointObj = (obj, timelapseObj, history)
            %                        
            % Input:     obj = an object of the StandardTLSeg class.
            %            timelapseObj = an object of a Timelapse class
            %            history = structure, contains details of objects used so far in timelapse segmentation
            %
            % Output:    timepointObj = an object of class Timepoint3

            % Notes: This method performs the segmentation of a single
            %        timepoint. When called from the GUI it may be used to
            %        evaluate methods and parameters for segmentation. The
            %        only difference from the code called during timelapse
            %        segmentation is that the timepointObj.Result field is
            %        populated.
            
            disp('works')
%             filename=[timelapseObj.ImageFileList.directory '/' timelapseObj.ImageFileList(timelapseObj.Main).file_details(timelapseObj.CurrentFrame).timepoints.name];
%             try
%                 image=imread(filename);
%             catch
%                 showMessage([filename ' may not be an image file']);
%             end
%             timepointObj=Timepoint3(image,timelapseObj,timelapseObj.CurrentFrame,history);
%             timepointObj.Result=timelapseObj.Result(timelapseObj.CurrentFrame).timepoints;
%             showMessage(['Timepoint ' num2str(timelapseObj.CurrentFrame) 'segmentation completed']);
        end
        
    end
end