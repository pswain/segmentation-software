classdef Timepoint4<Timepoint
   properties
   end 

   methods              
        function obj=Timepoint4(timelapseObj, frame)
           % Timepoint4 --- constructor for Timepoint4 object, creates a timepoint object without attempting segmentation
           %
           % Synopsis:  timepoint = Timepoint4 (timelapseObj, index)
           %            timepoint = Timepoint4 ('Blank')
           %
           % Input:     timelapseObj = an object of a Timelapse class
           %            frame = integer, the frame of the timepoint required
           %
           % Output:    timepointObj = object of class Timepoint2

           % Notes:  Use the alternative class Timepoint3 for segmenting
           %         from scratch. Use the class Timepoint2 for recreating
           %         Timepoint object from information stored in the
           %         timelapseObj.LevelObjects array. This class is used to
           %         create a Timepoint object for use by the GUI in the
           %         case where no Timepoint object has been created during
           %         the initial timelapse segmentation.   This constructor
           %         will also take a string input - returns an empty
           %         object in that case for blank constructor used by the
           %         copy function.
           
           if ~ischar(timelapseObj)
               obj.Frame=frame;
               obj.Timelapse = timelapseObj;
               obj.ObjectNumber=obj.Timelapse.NumObjects;
               obj.Timelapse.NumObjects=obj.Timelapse.NumObjects+1;
               %Get the run method
               obj.RunMethod=obj.Timelapse.getobj('runmethods','RunTpSegMethod');     
               dir=timelapseObj.ImageFileList.directory;
               for main=1:size(timelapseObj.ImageFileList,2)
                   if strcmp(timelapseObj.ImageFileList(main).label,'main')
                       break;
                   end           
               end
               filename=timelapseObj.ImageFileList(main).file_details(frame).timepoints.name;          
               obj.Target=imread([dir filesep filename]);
           end
        end
   end
end