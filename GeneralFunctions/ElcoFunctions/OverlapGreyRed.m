function [show_stack] = OverlapGreyRed(BaseImage,HighlightImage,UseNeg,HighlightImage2,TreatAsLogical,NoNormalisation,ImageRange)
%[show_stack] = BaseImage,HighlightImage,UseNeg,HighlightImage2,TreatAsLogical,NoNormalisation,ImageRange)
%make an image that is grey BaseImage with red highlight of HighLightImage and blue highlight of highlight image 2;
%
%  ARGUMENTS
%
% BaseImage         -   the iamge that will be grey scaled
% HighlightImage    -   the red highlight image
% UseNeg            -   logical -whether to maintain the negative part of a
%                       highlight image (so that negative areas will appear
%                       opposite of red)
% HighlightImage2   -   blue highlight image
% TreatAsLogical    -   treat highlight image as logical (so just make
%                       positive bits a flat red/green colour)
% NoNormalisation   -   scale so the dynamic range of the image is between ImageRange(i,:) in
%                       each channel i (i = 1 => base , i=2 => highlight
%                       i = 3 => highligh2
% ImageRange        -   range to use of NoNormalisation is true.
%
% Notes on return scale. If TreatAsLogical is true the image will be
% between 0 and 0.8, with highlights set to 1 in the appropriate slice.
% If this is not so, the image will be between 0 and 1, with a pixel with
% no highlights being 0.5 in all channels.


if nargin<6 || isempty(NoNormalisation)
    NoNormalisation = false;
end

if nargin<7 || isempty(ImageRange)
    NoNormalisation = false;
end


if NoNormalisation
    
    BaseImage = IMNormalise3(BaseImage,ImageRange(1,:));
    
else
    BaseImage = IMNormalise(BaseImage);
end


if nargin<2 || isempty(HighlightImage) 
    
    HighlightImage = zeros(size(BaseImage));
    
end

if nargin<4 || isempty(HighlightImage2)
    
    HighlightImage2 = zeros(size(BaseImage));
    
end

if NoNormalisation && size(ImageRange,1)>1
    
    HighlightImage = IMNormalise3(HighlightImage,ImageRange(2,:));
    
else
    
    if nargin<3 || isempty(UseNeg) || ~UseNeg
        
        HighlightImage = IMNormalise(HighlightImage);
        
    else
        
        HighlightImage = IMNormalise2(HighlightImage);
        
    end
    
end

if NoNormalisation && size(ImageRange,1)>2
    
    HighlightImage2 = IMNormalise3(HighlightImage2,ImageRange(3,:));
    
else
    
    if nargin<3 || isempty(UseNeg) || ~UseNeg
        
        HighlightImage2 = IMNormalise(HighlightImage2);
        
    else
        
        HighlightImage2 = IMNormalise2(HighlightImage2);
        
    end
    
end

if nargin<5 || isempty(TreatAsLogical)
    TreatAsLogical = false;
end


if TreatAsLogical
    
    im1 = 0.8*BaseImage;
    im2 = im1;
    im3 = im1;
    im1(HighlightImage>0) = 1;
    im2(HighlightImage2>0) = 1;
    show_stack = cat(3,im1,im2,im3);
    
    
else    
    show_stack = repmat(BaseImage,[1 1 3]).*(cat(3,1+HighlightImage , 1+HighlightImage2 , ones(size(HighlightImage))));
    show_stack = show_stack/2;
end

end

function Image = IMNormalise(Image)

if ~islogical(Image)

Image = Image - min(Image(:));
m = max(Image(:));
if m>0
    Image = Image/(max(Image(:)));
end

end

end

function Image = IMNormalise2(Image)

if ~islogical(Image)

m = max(Image(:));
if m>0
    Image = Image/(max(Image(:)));
end

end
end

function Image = IMNormalise3(Image,ImageRange)
    Image(Image < ImageRange(1)) = ImageRange(1);
    Image(Image > ImageRange(2)) = ImageRange(2);
    Image = Image-ImageRange(1);
    Image = Image/(ImageRange(2)-ImageRange(1));
end