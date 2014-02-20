classdef MethodsSuperClass
    %superclass for trackmethod classes.
    properties
        parameters%structure of parameters required for each method
        paramHelp=struct;%Strings describing each of the parameters
        paramChoices=struct;%Structure with an entry for each parameter that has a limited range of values to be selected by a drop down list
        paramCall=struct;%Structure with an entry for each parameter that may be set with a function called from the GUI
        Info;%Used by the segmentation editing gui to get the details of the class and its package etc.
        description='';%Displayed by the segmentation editing GUI
        levelObjects;%array of integers, the level object numbers that this method object has processed
        ObjectNumber;%integer, unique identifier for each object
        Classes=struct;%Structure. List of other method and level classes that are used by this method.
        requiredFields%Cell array of strings, list of fields that must be populated to allow the method to work        
        requiredImages%Cell array of strings, list of images that must be populated to allow the method to work
       
    end
    methods (Static)
       [history levelObj]=insertFieldHistory(history, fieldHistory, fieldIndex, levelObj);
       fieldHistory=addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
       [inputObj fieldHistory] = useMethodClass(varargin)
       classNames=listMethodClasses(package);
       packageNames=listMethodPackages;
       showProgress(percent,message);
       
    end    
    methods
        function showDisplayResult(obj, inputObj, axesHandle)
            % showDisplayResult---  Displays the result image of the currentmethod
            %
            % Synopsis:        showDisplayResult(obj, inputObj)
            %
            % Input:           obj = an object of a MethodsSuperClass subclass
            %                  inputObj = an object of a LevelObjects class
            %                  axesHandle = handle to the axis on which to display the result
            % 
            % Output:          

            % Notes:    Displays the result image. If the result is not an
            %           image then this method may be overloaded to
            %           generate a visible result. eg the FindCentres
            %           superclass has a showDisplayResult method that
            %           displays the found centre positions on the target
            %           image.
            
            axes(axesHandle);
            if strcmp(obj.resultImage,'Result')
                result=inputObj.makeDisplayResult;
                imshow(result);
            elseif isfield(inputObj.RequiredImages,obj.resultImage)
                imshow(inputObj.RequiredImages.(obj.resultImage));
            end
        end
    end
    
end