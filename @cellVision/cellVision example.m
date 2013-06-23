
%% Identify the trap outline
cCellVision.identifyTrapOutline(cTimelapse,7);
figure(1);imshow(cCellVision.cTrap.trapOutline,[]);
%%
trap=19;
for i=1:size(cDictionary.cTrap(trap).image,3)
    figure(234);imshow(cDictionary.cTrap(trap).image(:,:,i),[]);
    pause(.01);
end
%%
step_size=1;
cCellVision.generateTrainingSetTimelapse(cDictionary,step_size);

%%
cCellVision.trainingParams.cost=.25
cCellVision.trainingParams.gamma=1
%%
step_size=20;
cCellVision.runGridSearchLinear(step_size);
%%
step_size=1;
cCellVision.trainingParams.cost=1;
cmd = ['-s 1 -w0 2 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];
tic
cCellVision.trainSVMLinear(step_size,cmd);toc
%%
%%
cCellVision.twoStageThresh=1;
step_size=1;
cCellVision.generateTrainingSet2Stage(cDictionary,step_size);
%%
step_size=75;
cmdin='-t 2 -w0 1 -w1 2 '
cCellVision.runGridSearch(step_size,cmdin);
%%
cCellVision.trainingParams.cost=1
cCellVision.trainingParams.gamma=.5 %or 2 and .25 or 2 and 1 or 1 and 2

%
step_size=10;
cmd = ['-t 2 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost),' -g ',num2str(cCellVision.trainingParams.gamma)];
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
num_frames=[1 500];
cCellVision.cTrap.Prior=.8;
cCellVision.cTrap.thresh=1.1;
cCellVision.cTrap.thresh_first=.4;
cCellVision.cTrap.objective=100

cTimelapse.identifyTrapLocations(cCellVision,display,num_frames);
cTimelapse.trackTrapsThroughTime();



%%
trap_im=cTimelapse.returnSingleTrapTimepoint(7,50,1);
% trap_im=cDictionary.cTrap(1).image(:,:,1);
tic
[p_im d_im]=cCellVision.classifyImage2Stage(trap_im);toc

% [p_im d_im]=cCellVision.classifyImageLinear(trap_im);toc
toc
% [p_im d_im]=cCellVision.classifyImage(trap_im);toc

figure(1);imshow(p_im,[]);
% figure(2);imshow(imfilter(d_im,fspecial('disk',1)),[]);impixelinfo
figure(3);imshow(trap_im,[]);
figure(4);imshow(d_im,[]);impixelinfo


%%
trap_im=cTimelapse.returnSingleTrapTimelapse(8,1);
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

bw_l=bwlabel(bw);
props=regionprops(bw_l);
for i=1:length(props)
    if props(i).Area<4
        bw(bw_l==i)=0;
    end
end

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
image=cTimelapse.returnSingleTrapTimepoint(5,20);
figure(1);imshow(image,[]);
%%
tic
% image=trap_im;
features=cCellVision.createImFilterSetCellTrap(image);
toc
im_feat=reshape(features,size(image,1),size(image,2),size(features,2));
    
for i=1:size(im_feat,3)
    figure(1);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
    pause(.5);
end

figure(2);imshow(image,[])
%%
i=1
figure(1);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
i=i+(5-i)+(i-1)*5+0;
figure(2);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
%%
i=10
figure(4);imshow(im_feat(:,:,i),[],'InitialMagnification',400);title(int2str(i));
%%
image=cTimelapse.returnSingleTrapTimepoint(1,38);
image=double(image);
temp_im=imfilter(image,fspecial('log',5,1),'replicate');
figure(1);imshow(temp_im,[],'InitialMagnification',400);

figure(2);imshow(image,[],'InitialMagnification',400);
