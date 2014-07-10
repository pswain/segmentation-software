%% Create the ground truth data
file='C:\Users\Matt\SkyDrive\timelapses\13-Jun 2014 (robin)\1-Pos_000_000cTimelapse.mat';
file='/Users/mcrane2/SkyDrive/timelapses/13-Jun 2014 (robin)/1-Pos_000_000cTimelapse.mat';

load(file);
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:15:end);
cTimelapse.timepointsProcessed=cTimelapse.timepointsProcessed(1:15:end);

%%

load('C:\Users\mcrane2\OneDrive\timelapses\DR robin\04-Jul 2014\pois 0 for training.mat')


% cTimelapseOut = fuseTimlapses({cTimelapseOut,cTimelapse});
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:40);
cTimelapse.channelsForSegment=[1 2 3]
cTimelapse = fuseTimlapses({cTimelapse});

%%
cTrapDisplay(cTimelapse,cCellVision);
%%
cTrapDisplayProcessing(cTimelapse,cCellVision);

%%
load('cCellVision default Robin reduced.mat')
%% Create the training set
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
cCellVision.negativeSamplesPerImage=600; %set to 750 ish for traps
step_size=1;

cCellVision.generateTrainingSetTimelapse(cTimelapse,step_size,@(CSVM,image) createImFilterSetCellTrapStackDIC(CSVM,image));

%% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2
cCellVision.trainingParams.gamma=1
%%
cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
step_size=20;
cCellVision.runGridSearchLinear(step_size,cmd);
%%
step_size=1;
cCellVision.trainingParams.cost=2;
cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];
tic
cCellVision.trainSVMLinear(step_size,cmd);toc
%%
%%

step_size=3;
cCellVision.generateTrainingSet2Stage(cTimelapse,step_size);
%%
step_size=29;
cCellVision.runGridSearch(step_size);
%%
cCellVision.trainingParams.cost=2;
cCellVision.trainingParams.gamma=2;

%%
step_size=13;
cmd = ['-t 2 -w0 1 -w1 2 -c ', num2str(cCellVision.trainingParams.cost),' -g ',num2str(cCellVision.trainingParams.gamma)];
tic
cCellVision.trainSVM(step_size,cmd);toc

%%
folder='/Users/mcrane/TimelapseImages'
cTimelapse=timelapseTraps();
searchString{1}='DIC';
searchString{2}='GFP';
cTimelapse.loadTimelapse(searchString);
%%  identify traps throughput the timelapse
display='all' %'all' or 'cc' or 'images' or 'none'
num_frames=[1 250];
cCellVision.cTrap.Prior=.8;
cCellVision.cTrap.thresh=1.1;
cCellVision.cTrap.thresh_first=.8;
cCellVision.cTrap.objective=60

cTimelapse.identifyTrapLocations(cCellVision,display,num_frames);
cTimelapse.trackTrapsThroughTime();



%%

trap_im=cTimelapse.returnSingleTrapTimepoint(3,3,1);
% trap_im=cDictionary.cTrap(1).image(:,:,1);
tic
[p_im d_im]=cCellVision.classifyImage2Stage(trap_im);toc

% [p_im d_im]=cCellVision.classifyImageLinear(trap_im);toc
toc
% [p_im d_im]=cCellVision.classifyImage(trap_im);toc

figure(11);imshow(p_im,[]);
% figure(2);imshow(imfilter(d_im,fspecial('disk',1)),[]);impixelinfo
figure(3);imshow(trap_im,[]);
figure(4);imshow(d_im,[]);impixelinfo;colormap(jet)


%%
trap_im=cTimelapse.returnSingleTrapTimelapse(5,1);
%%
trap_im=imresize(trap_im,.6);
%%
figure(1);fig1=gca;
figure(2);fig2=gca;
figure(3);fig3=gca;
figure(4);fig4=gca;

for i=1:size(trap_im,3)
tic
image=trap_im(:,:,i);
% [p_im d_im]=cCellVision.classifyImage2Stage(image);toc
[p_im d_im]=cCellVision.classifyImageLinear(image);toc
% [p_im d_im]=cCellVision.classifyImage(image);toc


imshow(p_im,[],'Parent',fig1);
imshow(d_im,[],'Parent',fig2);
imshow(image,[],'Parent',fig3);

t_im=imfilter(d_im,fspecial('disk',1));
imshow(t_im<cCellVision.twoStageThresh,[],'Parent',fig4);
pause(.01);
% figure(4);imshow(medfilt2(d_im)<0,[],'InitialMagnification',300);pause(.001);
end

%%
figure(1);fig1=gca;
figure(2);fig2=gca;
figure(3);fig3=gca;
figure(4);fig4=gca;

for i=1:size(trap_im,3)
    i
tic
image=trap_im(:,:,i);
[p_im d_im]=cCellVision.classifyImage2Stage(image);toc
% [p_im d_im]=cCellVision.classifyImageLinear(image);toc

t_im=imfilter(d_im,fspecial('disk',1));
bw=t_im<0;

[accum circen cirrad] =CircularHough_Grd_matt(image,[cCellVision.radiusSmall cCellVision.radiusLarge],bw);

% [p_im d_im]=cCellVision.classifyImageLinear(image);toc

imshow(p_im,[],'Parent',fig1);
imshow(d_im,[],'Parent',fig2);
imshow(image,[],'Parent',fig3);
 hold on;
 plot(circen(:,1), circen(:,2), 'r+');
 for k = 1 : size(circen, 1),
     DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
 end
 hold off;

imshow(t_im<0,[],'Parent',fig4);
pause(.1);
% figure(4);imshow(medfilt2(d_im)<0,[],'InitialMagnification',300);pause(.001);
end


















%%
tic
traps=1:length(cTimelapse.cTrapsLabelled);
cTimelapse.identifyCells(cCellVision,traps,1,'twostage')
toc
%%
tic
cTimelapse.identifyCellObjects(cCellVision,traps,1,'hough')
toc
%%

%%
cDisplay=cTrapDisplay(cTimelapse,traps,'circleDIC')
%%
cDisplay=cTrapDisplay(cTimelapse,traps,'segDIC')

%%
cDisplay=cTrapDisplay(cTimelapse,traps,1)


%%
trap1 = cTimelapse.returnSegmenationTrapsStack(17,cTimelapse.timepointsToProcess(1));
%%
tic
% image=trap_im;
features=cCellVision.createImFilterSetCellTrapStackDIC(trap1{1});
image=trap1{1};
toc
im_feat=reshape(features,size(image,1),size(image,2),size(features,2));
    
for i=1:size(im_feat,3)
    figure(1);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
    pause(.5);
end

figure(12);imshow(image(:,:,3),[]);impixelinfo
%%
image = cTimelapse.returnSingleTimepoint(17);
figure(12);imshow(image,[]);impixelinfo

%%
i=2
figure(1);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
i=i+(5-i)+(i-1)*5+0;
figure(2);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
%%
i=54
figure(4);imshow(im_feat(:,:,i),[],'InitialMagnification',400);title(int2str(i));
%%
image=cTimelapse.returnSingleTrapTimepoint(1,38);
image=double(image);
temp_im=imfilter(image,fspecial('log',5,1),'replicate');
figure(1);imshow(temp_im,[],'InitialMagnification',400);

figure(2);imshow(image,[],'InitialMagnification',400);
