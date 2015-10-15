function [filledImg]=fillEdge(varargin)
    % fillEdge --- Performs imfill on input image then imopen. if from a split region, applies watershed lines before filling
    %
    % Synopsis:  [filledImg] = fillEdge (edgeImage, SE)
    %            [filledImg] = fillEdge (edgeImage, SE, watershed)
    %                        
    % Input:     edgeImage = 2d logical matrix, image showing the detected edges in an image to be filled
    %            SE = structuring element, for image opening to remove single pixel lines
    %            watershed = 2d matrix, output of watershed transform
    %
    % Output:    filledImg = 2d logical matrix, filled in and opened image

    % Notes:     For cells in regions that have been split with the
    %            watershed transform the third input is used to define the
    %            boundary lines of the catchment basins. These are used to 
    %            complete fillable structures and are removed by the imopen
    %            command. In case of multiple filled objects returns an
    %            image having only the largest object in the filled image.
   
    edgeImage=varargin{1};
    SE=varargin{2};
    if nargin==3
       wshimage=varargin{3};
       edgeImage(wshimage==0)=1;%Fills in watershed lines - can create fillable areas
    end
    filledImg=imfill(edgeImage,'holes');
    filledImg=imopen(filledImg,SE);
    %now find the largest object and leave only that in the image            
    objs=regionprops(filledImg,'Area','PixelList');
    objAreas=vertcat(objs.Area);
    [c I]=max(objAreas);%I is the index of the largest object
    pixels=vertcat(objs(I).PixelList);%the x and y coordinates of the pixels making up the object
    %Define a new filledImage consisting only of the largest object.   
    filledImg=zeros(size(edgeImage));
    for i=1:size(pixels,1)
        filledImg(pixels(i,2), pixels(i,1))=1;
    end     
end