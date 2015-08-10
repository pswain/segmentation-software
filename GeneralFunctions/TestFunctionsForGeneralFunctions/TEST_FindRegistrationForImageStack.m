%%setup images


BaseImageSize = 501;
BaseImage = rand(BaseImageSize,BaseImageSize);
BaseImage = zeros(size(BaseImage));
BaseImage(200:301,200:301) = 1;
MaxOffset = 20;
StackDepth = 5;
StackImageSize = BaseImageSize - 2*MaxOffset;

%% construct test case

GivenOffsets = cat(1,[0 0],randi([-MaxOffset MaxOffset],[StackDepth-1 2]));

ImageStack = zeros(StackImageSize,StackImageSize,StackDepth);

for slicei = 1:StackDepth
    
    
    ImageStack(:,:,slicei) = BaseImage(GivenOffsets(slicei,1)+MaxOffset+(1:StackImageSize),GivenOffsets(slicei,2)+MaxOffset+(1:StackImageSize));
    
end

%% test registration function

%no extra variables
Offsets = FindRegistrationForImageStack(ImageStack);

if any(Offsets~=GivenOffsets)
    
    fprintf('FAIL!!!\n')
else
    fprintf('success \n')
    
end


% give even max offset
Offsets = FindRegistrationForImageStack(ImageStack,[],20);

if any(Offsets~=GivenOffsets)
    
    fprintf('FAIL!!!\n')
else
    fprintf('success \n')
    
end


% give odd max offset
Offsets = FindRegistrationForImageStack(ImageStack,[],20);

if any(Offsets~=GivenOffsets)
    
    fprintf('FAIL!!!\n')
else
    fprintf('success \n')
    
end


%% test registration

RecoveredImageStack = RegisterImages(ImageStack,Offsets,MaxOffset);
Variance = var(RecoveredImageStack,1,3);
if any(Variance(:))
    fprintf('FAIL on RegisterImage\n')
else
    fprintf('success \n')
end
    