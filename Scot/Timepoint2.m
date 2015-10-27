classdef Timepoint2<Timepoint
   properties
       MethodObject%Object used in segmentation of the timepoint
   end 

   methods              
        function obj=Timepoint2(timelapseObj, index)
           % Timepoint2 --- constructor for Timepoint2 object, recreates timepoint object based on information stored in Timelapse.LevelObjects
           %
           % Synopsis:  timepoint = Timepoint2 (timelapseObj, index)
           %            timepoint = Timepoint2 ('Blank')
           %
           % Input:     timelapseObj = an object of a Timelapse class
           %            index = integer, the index to the entry for the timepoint object required, in the timelapseObj.LevelObjects structure
           %
           % Output:    timepointObj = object of class Timepoint2

           % Notes:  Use the alternative class Timepoint3 for segmenting
           %         from scratch. This constructor is used to recreate a
           %         Timepoint object from information stored in the
           %         timelapseObj.LevelObjects array. This saves the memory
           %         cost of storing the objects themselved. This method is
           %         called by the Timelapse method LevelObjFromNumber.
           %         This constructor will also take a string input - 
           %         returns an empty object in that case for blank
           %         constructor used by the copy function.
           
               
           if ~ischar(timelapseObj)
               obj.ObjectNumber=timelapseObj.LevelObjects.ObjectNumber(index);
               obj.Frame=timelapseObj.LevelObjects.Frame(index);
               obj.RunMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.RunMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.SegMethod=timelapseObj.methodFromNumber(timelapseObj.LevelObjects.SegMethod(index));%Gets the method object corresponding to the saved objectnumber
               obj.Timelapse = timelapseObj;
           end
        end



   end
end