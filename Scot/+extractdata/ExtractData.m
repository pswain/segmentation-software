classdef ExtractData<MethodsSuperClass
   properties
       datafield;%string, the field name of the result array, stored in timelapseObj.Data
       plottype='Scatter';%Can define plottype as 'Histogram' in the subclass constructor - for methods that produce only one number per cell - not one per timepoint
       resultImage='Result';
   end
   
   methods
       timelapseObj=run(obj,timelapseObj);       
   end
   methods (Static)
      function subtractedImage=subtractBackground(image, timelapseObj, frame)
            % run --- subtracts the background from an input image
            %
            % Synopsis:  subtractedImage=subtractBackground(image, timelapseObj, frame)
            %
            % Input:     image = 2d uint8 or uint16 array, image to process
            %            timelapseObj = an object of a timelapse class that has been segmented
            %            frame = integer, the frame of the timelapse that is represented by image
            %
            % Output:    subtractedImage = 2d double array

            % Notes:     This method uses the timelapseObj and frame inputs
            %            to identify foreground and background pixels, and
            %            subtracts the mean value of background pixels from
            %            the whole image. Assumes a uniform background -
            %            image should be pre-processed to ensure this if
            %            necessary.
                            
            if isempty (timelapseObj.DisplayResult)
                thisFrameResult=false(size(timelapseObj.Result(frame).timepoints(1).slices));
                for n=1:size(obj.Result(t).timepoints,2)
                    thisFrameResult=thisFrameResult | timelapseObj.Result(frame).timepoints(n).slices;       
                end
            else
                thisFrameResult=timelapseObj.DisplayResult(frame).timepoints;
            end
            
            background=mean(image(thisFrameResult));            
            background=mean(background);            
            subtractedImage=image-background;
            subtractedImage(subtractedImage<0)=0;         
      end 
   end
    
    
    
end