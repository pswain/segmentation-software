classdef Timepoint3<Timepoint
   properties
   end
   
   

   methods              
        function obj=Timepoint3(image, Timelapse, thistimepoint, history)
           % Timepoint3 --- constructor for Timepoint3 object, segments input image
           %
           % Synopsis:  timepoint=Timepoint3(image,Timelapse) 
           %            timepoint=Timepoint3(image,Timelapse,thistimepoint)
           %
           % Input:     image = 2d array, the image to be segmented
           %            timelapse = an object of a Timelapse class
           %            thistimepoint = integer, the number of the timepoint
           
           %
           % Output:    obj = object of class Timepoint3

           % Notes:     This constructor performs segmentation of the input
           %            image and writes the results to the input timelapse
           %            object
           %            
           obj.Frame=thistimepoint;
           obj.Timelapse = Timelapse;
           obj.ObjectNumber=obj.Timelapse.NumObjects;
           obj.Timelapse.NumObjects=obj.Timelapse.NumObjects+1;
           %Get the run method
           obj.RunMethod=obj.Timelapse.getobj('runmethods','RunTpSegMethod');     
           obj.Target=image;
           %Run the segmentation.           
           obj=obj.RunMethod.run(obj, history);
        end
   end
end