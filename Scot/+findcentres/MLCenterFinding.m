classdef MLCenterFinding<findcentres.FindCentres
    methods
        function obj=MLCenterFinding (varargin)
            % MLCenterFinding --- constructor for an object to run a simple findcentres method that returns the centroids of the latest entry in RequiredImages.Bin
            %
            % Synopsis:  obj = MLCenterFinding (varargin)
            %                        
            % Output:    obj = object of class MLCenterFinding

            % Notes:                
            
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.decisionThresh=0;
            obj.parameters.cellVisionFile='CellVisionAsicTesting.mat';
            obj.paramCall.cellVisionFile='uigetfile';
            obj.parameters.method='linear';
            obj.paramChoices.method={'linear';'kernel';'twostage'};
            obj.parameters.pixelSize=.16;
            
            
            %Define required fields and images
            obj.requiredImages={'bw','dec_im'};
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description='Finds the centers of cells in the image using a trained computer vision model';
            obj.paramHelp.decisionThresh = 'Threshold used to identify cell centers, >0 is more lenient, <0 is less lenient. Change in small increments (ie 0.1).';
            obj.paramHelp.cellVisionFile = 'The filename that contains the CellVisionModel. If it is not in the same folder as SCOT than the entire name must be used';
            obj.paramHelp.method = 'The SVM type to use to classify the image. Use linear unless otherwise specified (choices are: linear, kernel, twostage).';
            obj.paramHelp.pixelSize='This is the pixel size of the camera that you are using with the current magnification';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});

        end
        
        function paramCheck=checkParams(obj, timelapseObj)
           % checkParams --- checks if the parameters of a Threshold object are in range and of the correct type
           %
           % Synopsis: 	paramCheck = checkParams (obj)
           %
           % Input:	obj = an object of class LoopBasins
           %
           % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect

           % Notes:  
           paramCheck='';
           if ~isnumeric(obj.parameters.decisionThresh)
              paramCheck=[paramCheck 'decisionThresh must be a number.'];
           end
           
           if isempty(paramCheck)
               paramCheck='OK';               
           end            
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the fields and images required for the CentroidsOfBin method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %                        
            % Output:    obj = object of class CentroidsOfBin
            %            inputObj = an object of a level class.

            % Notes:     Uses a method in the findcentres class to create
            % the inputObj.RequiredFields.Centres field.
            
           fieldHistory=struct('objects', {},'fieldnames',{});
           field=isfield(inputObj.RequiredImages,'FilteredTargetImage');
           obj.parameters.cellVisionFile='/Users/iclark/Documents/YeastSegmentation/CellSegMatt/cellvision models/Hillary.mat'     
            load(obj.parameters.cellVisionFile);
            cCellVision.pixelSize=obj.parameters.pixelSize;
            image=imresize(inputObj.Target,obj.parameters.pixelSize/cCellVision.pixelSize);
            switch obj.parameters.method
                case 'linear'
                    [p_im d_im]=cCellVision.classifyImageLinear(image);
                case 'kernel'
                    [p_im d_im]=cCellVision.classifyImage(image);
                case 'twostage'
                    [p_im d_im]=cCellVision.classifyImage2Stage(image);
            end
            
            t_im=imfilter(d_im,fspecial('gaussian',3,.4));
            t_im=imresize(t_im,cCellVision.pixelSize/obj.parameters.pixelSize);
            inputObj.RequiredImages.dec_im=t_im;
            inputObj.RequiredImages.bw=t_im<obj.parameters.decisionThresh;

           
        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for CentroidsOfBin, finds cell outlines from centres and input image
            %
            % Synopsis:  result = run(obj, inputObj)
            %                        
            % Input:     obj = an object of class CentroidsOfBin
            %            inputObj = an object carrying the data to be operated on
            %
            % Output:    inputObj = level object with inputObj.RequiredFields.Centres created or modified

            % Notes:     
            
            fieldHistory=struct('fieldnames',{},'objects',{});

            props=regionprops(inputObj.RequiredImages.bw);
            centers=[props.Centroid];
            inputObj.RequiredFields.Centres=reshape(centers,2,length(centers)/2)';  
            
        end
    end
end