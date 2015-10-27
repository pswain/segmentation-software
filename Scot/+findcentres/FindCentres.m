classdef FindCentres <MethodsSuperClass
    properties
        resultImage='RequiredFields.Centres';
        %n x 2 matrix, [x y] where xis distance from the left side of the
        %image and y is distance down from the top of the image (following
        %the convention of the 'centroid' fields in the 'trackingdata'
        %structure.
    end
    methods (Abstract)
        inputObj=run(obj,input);%the run method writes the result to inputObj.RequiredImages.Bin
        inputObj=initializeFields(inputObj);
    end
    methods
        function showDisplayResult(obj, inputObj, axesHandle)
            % showDisplayResult---  Displays a result image to display the positions of found centres
            %
            % Synopsis:        resultImage=showDisplayResult(obj, inputObj)
            %
            % Input:           obj = an object of a FindCentres subclass
            %                  inputObj = an object of a LevelObjects class
            %                  axesHandle = handle to the axis on which to display the result
            % 
            % Output:          

            % Notes:    Displays an image that will display the result of
            %           the centre finding method. This image is not
            %           included in the requiredImages list because there
            %           is no need to waste time creating it during a
            %           segmentation run - only used during timelapse
            %           editing.
            
            if isfield(inputObj.RequiredFields,'Centres')
                axes(axesHandle);imshow(inputObj.Target,[]);
                hold on;
                plot(inputObj.RequiredFields.Centres(:,1),inputObj.RequiredFields.Centres(:,2),'Marker','x','MarkerEdgeColor','r','Line','none')
                hold off;            
            end
        end
        
    end
end