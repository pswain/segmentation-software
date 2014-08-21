%% test Elco image filter

IMin = zeros(512,512);
IMin(100:400,100:400) = 1000;
IMin(200:300,200:300) = 0;
IMin(220:280,220:280) = 1000;
imshow(IMin,[]);

RadRange = [3 13];

%% test on image from cTimelapse

IM = cTimelapse.returnSegmenationTrapsStack(1,5);
IM = IM{1};

grd_thresh = 0;%{99.9};
RadRange = [3 13];

for slicei = 1:size(IM,3)
    
    tic;[IMoutPOS,IMoutNEG] = ElcoImageFilter(IM(:,:,slicei),RadRange,grd_thresh);toc
    figure(3);imshow(IMoutPOS,[]);
    figure(4);imshow(IMoutNEG,[]);
    figure(5);imshow(IM(:,:,slicei),[]);
    pause
    
end