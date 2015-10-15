function Offsets = FindRegistrationForImageStack(ImageStack,varargin)
%Offsets = FindRegistrationForImageStack(ImageStack,varargin) a function to find
%the registration of a stack of image (the amount the images have to be
%shifted relative to a base image for best alignment according to a cross
%correlation metric. 
%currently won't work very well for large shifts.
%
%inputs
%ImageStack     -     the stack of images to be registerd
%
%optional inputs
%
%1-BaseImage      -     the index of the image in the stack to use as the
%                       base image for registration
%
%2-MaxOffset      -     The macximum allowed offset across the stack. This
%                       also sets the size of the central region used to do
%                       the cross correlation, so shouldn't be too large.
%
%3-RenewThreshold -     if this input is given the base image is changed
%                       to be the current image everytime the absolute
%                       value of both the offsets is greater or equal to
%                       the RenewThreshold. If this is given then BaseImage
%                       input is set to 1 and the offset for the chosen
%                       base image subtracted to compensate.
%
%4-FlatRenewRate  -     If this is non empty it should be a number which
%                       indicates when the program should renew the image
%                       (i.e replace the base image with the current one)


if nargin>1 && ~isempty(varargin{1})
    BaseImageIndex = varargin{1};
else
    BaseImageIndex = 1;
end

if nargin>2 && ~isempty(varargin{2})
    MaxOffset = varargin{2};
else
    MaxOffset = 10;
end
    

if nargin>3 && ~isempty(varargin{3})
    Renew = true;
    RenewThreshold = varargin{3};
    BaseImageIndex = 1;
    GivenBaseImageIndex = varargin{1};
else
    Renew = false;
    RenewThreshold = Inf;
    GivenBaseImageIndex = BaseImageIndex;
end

if nargin>4 && ~isempty(varargin{4})    
    ApplyFlatRenew = true;
    FlatRenewThrehold = varargin{4};
else
    ApplyFlatRenew = false;
end

CumulativeOffsetX = 0;
CumulativeOffsetY = 0;


OffsetX = 0;
OffsetY = 0;

OldIm = ImageStack(:,:,BaseImageIndex);

Offsets = zeros(size(ImageStack,3),2);

SlicesSinceRenew = 0;

for slicei=setxor(1:size(ImageStack,3),BaseImageIndex)
   
    NewIm = ImageStack(:,:,slicei);
    CrossCorrelation = normxcorr2(NewIm((MaxOffset+1):(end-MaxOffset),(MaxOffset+1):(end-MaxOffset)),OldIm);
    
    IRange = size(NewIm,1) - MaxOffset + [-(MaxOffset+1) (MaxOffset+1)];
    JRange = size(NewIm,2) - MaxOffset + [-(MaxOffset+1) (MaxOffset+1)];
    
    %size of cc is Image + 2*(floor(Image-(2*MaxOffset))/2)
    
    IRange(1) = max(IRange(1),1);
    IRange(2) = min(IRange(2),size(CrossCorrelation,1));
    
    JRange(1) = max(JRange(1),1);
    JRange(2) = min(JRange(2),size(CrossCorrelation,2));    
    
    CrossCorrelationCentre = CrossCorrelation(IRange(1):IRange(2),JRange(1):JRange(2));
    
    [I,J] = find(CrossCorrelationCentre==max(CrossCorrelationCentre(:)));
    OffsetX =  J - (MaxOffset+2) + CumulativeOffsetX;
    OffsetY =  I - (MaxOffset+2) + CumulativeOffsetY;
    
    if abs(OffsetX)>MaxOffset
        OffsetX = sign(OffsetX)*MaxOffset;
    end
    
    if abs(OffsetY)>MaxOffset
        OffsetY = sign(OffsetY)*MaxOffset;
    end
    
    Offsets(slicei,:) = [OffsetY OffsetX];
    
    SlicesSinceRenew = SlicesSinceRenew + 1;
    
    if Renew
        if abs(OffsetX-CumulativeOffsetX)>=RenewThreshold && abs(OffsetY - CumulativeOffsetY)>=RenewThreshold
    
            OldIm = NewIm;
            CumulativeOffsetX = OffsetX;
            CumulativeOffsetY = OffsetY;
            SlicesSinceRenew = 0;
    
        end
    end
    
    if ApplyFlatRenew && SlicesSinceRenew>FlatRenewThrehold
        
            OldIm = NewIm;
            CumulativeOffsetX = OffsetX;
            CumulativeOffsetY = OffsetY;
            SlicesSinceRenew = 0;
    end
    
end

Offsets = Offsets - repmat(Offsets(GivenBaseImageIndex,:),size(Offsets,1),1);


end