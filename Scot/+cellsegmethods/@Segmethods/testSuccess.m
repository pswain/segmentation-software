 function [success centroid]=testSuccess(result,minsize,maxsize)
    % testSuccess --- decides if a segmentation has succeeded or not
    %
    % Synopsis:  success = testSuccess(result)
    %                        
    % Input:     result = 2d logical matrix, result of segmentation
    %            minsize = minimum size (in pixels) of a segmented cell
    %            maxsize = maximum size (in pixels) of a segmented cell
    %
    % Output:    success = logical, 1 if segmentation has been successful, 0 if not

    % Notes:     This method can be replaced in subclasses to provide
    %            specific testSuccess methods for specific segmentation
    %            methods 
    if nargin==1
        minsize=200;
        maxsize=2000;
    end
    success=0;
    props=regionprops(result,'Area','PixelList','Eccentricity','EquivDiameter','MajorAxisLength','Centroid');
    numObj=size(props,1);%number of connected objects in the result image
    centroid=[0 0];
    for n=1:numObj
       %test of size and eccentricity of objects - are any within the accepted range?
       if props(n).Area>=minsize && props(n).Area<=maxsize && props(n).Eccentricity<0.8
            success=1;
            centroid=props(n).Centroid;
       end
    end
end