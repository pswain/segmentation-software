function [ ImageStack ] = GetStack( FileLocation,Identifier )
%[ ImageStack ] = GetStack( FileLocation,Identifier ) A function to return
%an image stack of a z stack as a 3D matrix. The intention is to use it
%for the creation of PSF's and running deconvolution from Matlab. Only
%works for images stored as .png's for now.
%   
% INPUTS
% 
% FileLocation - string: the directory in which the z stack is found
% Identifier   - string: the string common to files in the z stack

% OUTPUTS
%
% ImageStack - the stack of images as a 3D matrix

DirectoryInfo = dir(FileLocation);
Names = {DirectoryInfo.name};
RelevantFiles = Names(~cellfun('isempty',regexp(Names,['.*' Identifier '.*\.png'])));

if isempty(RelevantFiles)
    ImageStack = [];
else
    ImageStackCell = cell(size(RelevantFiles));
    for imagei=1:length(RelevantFiles)
        ImageStackCell{imagei} = imread(fullfile(FileLocation,RelevantFiles{imagei}));
    end
    ImageStack = cat(3,ImageStackCell{:});

end

