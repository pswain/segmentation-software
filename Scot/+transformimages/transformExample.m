classdef transformExample<transformimages.TransformImages
    methods
    function obj=transformExample (varargin)
                   
            obj.resultfield='transformExample';
        
            %Create obj.parameters structure and define default parameter value          
            obj.parameters = struct();
            obj.parameters.parameter1 = [8 25];
            obj.paramCall.parameter1='Elcogui(obj.par)'
            
            
            %Define required fields and images
            obj.requiredImages={'FilteredTargetImage'};
            %There are no non-image required fields for this class
            
            %Define user information
            obj.description=['Finds centres by performing a hough transform'...
                '(using the file exchange CircularHoughGrd function) and then' ... 
                ' performing a number of simple operations on the accumulator array to remove '...
                'points that are in the wrong part of the image or too close together'];
            obj.paramHelp.thresh = ['threhsold below which maxima in the accumulator are discarded. If centres are being missed this may be too high. If '...
                'erroneous centers far from cells are being found this may be too low.'];
            obj.paramHelp.radrange = ['the [minimum maximum] radius range over which the accumulator looks for circles. Measured in pixels, must be adjusted '...
                'for magnification changes or detecting small cells'];
            obj.paramHelp.gauss = ['width of gaussian (in pixels) used for smoothing the accumulator array before thresholding and processing. If' ...
                ' many centers are found close to each other for a single cell than try increasing this number. If cells are merged decrease it'];
            obj.paramHelp.minimum_cell_distance = 'Centres closer together than this number (in pixels) are averaged. Cruder than the gauss parameter.';
               
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %This class does not use any other method classes
            
    end
    end
    
end