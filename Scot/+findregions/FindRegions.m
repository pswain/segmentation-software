classdef FindRegions <MethodsSuperClass
    properties
        resultImage='RequiredImages.Bin';
    end
    methods (Abstract)
        inputObj=run(obj,input);%the run method writes the result to inputObj.RequiredImages.Bin
        inputObj=initializeFields(inputObj);
    end
    methods 
        function inputObj=removeMinMax(obj, inputObj)
           % removeMinMax --- removes objects in binary result image that are not between defined min + max sizes.
           %
           % Synopsis:  inputObj=removeMinMax(obj, inputObj)
           %                        
           % Input:     obj = an object of a FindRegions subclass
           %            inputObj = an object of a level class
           %
           % Output:    inputObj = an object of a level class
           %
           % Notes:	 Function to edit the results of findregions methods.
           %         Can be called from the run method of a findregions
           %         class after the result image
           %         (inputObj.RequiredImages.Bin) is created. If the class
           %         has parameters called min and/or max it will edit the
           %         result to remove objects that are out of range.
           
           if isfield(inputObj.RequiredImages,'Bin')
           
           bin=inputObj.RequiredImages.Bin(:,:,end);
           
           %props=regionprops(inputObj.RequiredImages.Bin(:,:,end),'Area','BoundingBox','Image');
           if isfield(obj.parameters,'min')
                bin=bwareaopen(bin,obj.parameters.min);
           end
           
           if isfield(obj.parameters,'max')
               tooBig=bwareaopen(bin,obj.parameters.max);%Gives an image consisting only of objects bigger than max              
               bin(tooBig)=false;
           end
           inputObj.RequiredImages.Bin(:,:,end)=bin;
           end
           
        end
            
            
        end
    end
