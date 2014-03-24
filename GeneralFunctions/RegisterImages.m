
function ImageStack = RegisterImages(InputImageStack,GivenOffsets,varargin)
%ImageStack = RegisterImages(InputImageStack,GivenOffsets,MaxOffset) sister
%function of the find registration. Applies the registration offset found
%to the images. Only keeps the centra region (i.e. within max offset, so
%doesn't padarray or anything like that).


if nargin>2
    MaxOffset = varargin{1};
    if size(MaxOffset,2) == 1
        MaxOffset = [1 1]*MaxOffset;
    end
else
    MaxOffset = max(GivenOffsets,[],1);
end

StackImageSize = [size(InputImageStack,1) size(InputImageStack,2)] - 2*MaxOffset;
StackDepth = size(InputImageStack,3);


ImageStack = zeros([StackImageSize StackDepth]);

for slicei = 1:StackDepth

    ImageStack(:,:,slicei) = InputImageStack(MaxOffset(1)-GivenOffsets(slicei,1)+(1:StackImageSize(1)),MaxOffset(2) - GivenOffsets(slicei,2) + (1:StackImageSize(2)),slicei);
    
end