function [TransformedImageStack ImageStack] = SimpleTransformOfSingleTimepoint(ttacObject,Timepoints,TrapIndices,CellIndices)
%TransformedImageStack = SimpleTransformOfSingleTimepoint(ttacObject,Timepoints,TrapIndices,CellIndices)

%takes Timepoints,TrapIndices and CellIndices and applies one of the
%trasforms from the +ACImageTransformation package to the stack of images

% INPUTS

% ttacObject    -  object of the timelapseTrapsActiveContour class

% Timepoints    -  1 x n vector of the timepoint of each cell to be transformed 

% TrapIndices   -  1 x n vector of the trapindex of each cell to be transformed

% CellIndices   -  1 x n vector of the cellindex of each cell to be transformed


%expects ttacObject.Parameters.ImageTransform to have the fields:

% ImageTransformFunction  -  string: name of the Tranform funciton in the
%                            ACImageTransformations package to use.

% channel                 -  Integer: which channel to apply the
%                            transformation

% TransformParameters     -  Structure: Parameter structure for the
%                            ImageTransformFunction


ImageStack = ttacObject.ReturnImageOfSingleCell(Timepoints,TrapIndices,CellIndices,ttacObject.Parameters.ImageTransformation.channel);


ImageTransformFunction = str2func(['ACImageTransformations.' ttacObject.Parameters.ImageTransformation.ImageTransformFunction]);

if ttacObject.TrapPresentBoolean  
    TrapImageStack =  ttacObject.ReturnTrapPixelsForSingleCell(Timepoints,TrapIndices,CellIndices);

    TransformedImageStack = ImageTransformFunction(ImageStack,ttacObject.Parameters.ImageTransformation.TransformParameters,TrapImageStack);
    
else
    TransformedImageStack = ImageTransformFunction(ImageStack,ITparameters);
end
   

end