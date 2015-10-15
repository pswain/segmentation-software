%% test Elco image filter

IMin = zeros(512,512);
IMin(100:400,100:400) = 5;
IMin(200:300,200:300) = 0;
IMin(240:260,240:260) = 10;
figure(1);imshow(IMin,[]);

RadRange = [3 4];

grd_thresh = 0;


tic;[IMoutPOS,IMoutNEG] = ElcoImageFilter(IMin,RadRange,grd_thresh);toc

%% test exclusion 

exclude = false(512,512);
exclude(1:200,:) = true;

tic;[IMoutPOS,IMoutNEG] = ElcoImageFilter(IMin,RadRange,grd_thresh,[],exclude);toc

%% test logical

tic;[IMoutPOS2,IMoutNEG2] = ElcoImageFilter(IMin,RadRange,grd_thresh,[],[],true);toc

figure(2);imshow(abs(IMoutNEG - IMoutNEG2),[]);

figure(3);imshow(abs(IMoutPOS - IMoutPOS2),[]);

%%
figure(2);imshow(OverlapGreyRed(IMin,IMoutNEG),[]);
figure(3);imshow(OverlapGreyRed(IMin,IMoutPOS),[]);


figure(2);imshow(IMoutNEG,[]);
figure(3);imshow(IMoutPOS,[]);


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

%% test on circles

noise_intensity = 0.5;

R_goal = 20;

R_range = [-3;-2;-1;0;1;2];

image_length = 50;

%%
xcoord = repmat(-image_length:image_length,(2*image_length +1),1);

ycoord = repmat((-image_length:image_length)',1,(2*image_length +1));

xcoord((image_length +1),(image_length +1)) = 1;

ycoord((image_length +1),(image_length +1)) = 1;

[R,angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,(2*image_length+1),(2*image_length+1));

angle = reshape(angle,(2*image_length+1),(2*image_length+1));


image_to_hough = ones(size(R));

image_to_hough(R<(R_goal)) = 2;

%%

image_to_hough = 1./(1+(R/R_goal).^3);

image_to_hough = 2*image_to_hough/(max(image_to_hough(:)));

imtool(image_to_hough,[])


%%

image_to_hough = image_to_hough + noise_intensity*rand(size(image_to_hough));


tic;[IMoutPOS,IMoutNEG] = ElcoImageFilter(image_to_hough,R_goal +[R_range-0.5 (R_range+0.5)]);toc

gui = GenericStackViewingGUI;
gui.stack = cat(3,IMoutPOS,image_to_hough);
gui.LaunchGUI;

%%

gui.stack = cat(3,IMoutNEG,image_to_hough);
gui.LaunchGUI;

%% 

[squeeze(max(max(IMoutNEG,[],2),[],1)) R_range R_goal*ones(size(R_range))]



