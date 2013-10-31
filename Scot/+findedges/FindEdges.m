classdef FindEdges <MethodsSuperClass
    properties
         resultImage='RequiredFields.TempResult';%reult image stack (i.e. each layer of stack is a binary image of an individual cell)
    end
    methods (Abstract)
        inputObj=run(obj,input);%the run method writes the result to inputObj.RequiredImages.Bin
        inputObj=initializeFields(inputObj);
    end
    methods 
                function showDisplayResult(obj, inputObj, axesHandle)
            % showDisplayResult---  Displays an image showing findeges result
            %
            % Synopsis:        resultImage=showDisplayResult(obj, inputObj)
            %
            % Input:           obj = an object of a FindEdges subclass
            %                  inputObj = an object of a LevelObjects class
            %                  axesHandle = handle to the axis on which to display the result
            % 
            % Output:          

            % Notes:    Displays an image that will display the result of
            %           the edge finding method. This image is not
            %           included in the requiredImages list because there
            %           is no need to waste time creating it during a
            %           segmentation run - only used during timelapse
            %           editing.
            

            if isfield(inputObj.RequiredFields,'TempResult')
                axes(axesHandle);imshow(inputObj.Target,[]);
                hold on;
                cc=hsv(size(inputObj.RequiredFields.TempResult,3));
                for n=1:size(inputObj.RequiredFields.TempResult,3)
                    bw=bwboundaries(inputObj.RequiredFields.TempResult(:,:,n));
                    bw=bw{:};
                    line(bw(:,2),bw(:,1),'color',cc(n,:));
                end
                hold off;
            end
           
            

        end
    end
end