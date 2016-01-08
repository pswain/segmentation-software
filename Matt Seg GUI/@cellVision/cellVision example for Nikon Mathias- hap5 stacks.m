%% Create the ground truth data
% file='C:\Users\Matt\SkyDrive\timelapses\13-Jun 2014 (robin)\1-Pos_000_000cTimelapse.mat';
% file='C:\AcquisitionDataRobin\Swain Lab\Matt\RAW DATA\2015\Jun\05-Jun-2015\Hap5_3.0DRglu_00\pos27cTimelapse';
load('E:\MSN2 Project\MSN2-GFP\SC_2%D\2015-12-21 msn2 Aging hapv3-4 62h\msn2 - 8ul-min_3\Pos1cTimelapse.mat')
% load(file);
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:35:650); 
% cTimelapse.timepointsProcessed=cTimelapse.timepointsProcessed(1:length(cTimelapse.cTimepoint));
cTimelapse.timepointsToProcess=cTimelapse.timepointsToProcess(1:length(cTimelapse.cTimepoint));
cTrapDisplayProcessing(cTimelapse,cCellVision);
%%
disp=cTrapDisplay(cTimelapse,cCellVision);
disp.channel=1;
%%
for i=1:length(cTimelapse.cTimepoint)
cTimelapse.cTimepoint(i).trapLocations(51:end)=[];
cTimelapse.cTimepoint(i).trapInfo(51:end)=[];
cTimelapse.cTimepoint(i).trapMaxCell(51:end)=[];
cTimelapse.cTimepoint(i).trapMaxCellUTP(51:end)=[];
end
%%
load('C:\Users\Kaeberlein\Documents\MATLAB\timelapse for cellvision\hapv5 3-4\pos2 2015-12-21 - ellipse centers.mat')
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:end);
cTimelapse.timepointsToProcess=1:length(cTimelapse.cTimepoint);
cTimelapse.channelsForSegment=[1 2 3]
cTimelapse.timepointsProcessed=1:length(cTimelapse.cTimepoint);

cTimelapseOut = fuseTimlapses({cTimelapse});


load('C:\Users\Kaeberlein\Documents\MATLAB\timelapse for cellvision\hapv5 3-4\pos1 2015-12-21.mat')
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:end-10);
cTimelapse.timepointsToProcess=1:length(cTimelapse.cTimepoint);
cTimelapse.channelsForSegment=[1 2 3]
cTimelapse.timepointsProcessed=1:length(cTimelapse.cTimepoint);

cTimelapseOut = fuseTimlapses({cTimelapse});
%

load('C:\Users\Kaeberlein\Documents\MATLAB\timelapse for cellvision\hapv5 3-4\pos12 2015-12-18.mat')
cTimelapse.cTimepoint=cTimelapse.cTimepoint(1:end-0);

cTimelapse.timepointsToProcess=1:length(cTimelapse.cTimepoint);
cTimelapse.channelsForSegment=[1 2 3]
cTimelapse.timepointsProcessed=1:length(cTimelapse.cTimepoint);

cTimelapseOut = fuseTimlapses({cTimelapseOut,cTimelapse});

%%
cTrapDisplay(cTimelapseOut,cCellVision);
%%
cTrapDisplay(cTimelapse,cCellVision);

%%
cTrapDisplayProcessing(cTimelapse,cCellVision);

%%
load('C:\Users\mcrane2\OneDrive\Matlab\CellSegMatt\cCellVision Robin Nov 1.mat')
%% Create the training set
cCellVision.trainingParams.cost=4;
cCellVision.trainingParams.gamma=1;
step_size=1;
    
tic
cCellVision.method='twostage'
% cCellVision.method='wholeIm'

if ~strcmp(cCellVision.method,'wholeIm')
    cCellVision.negativeSamplesPerImage=750; %set to 750 ish for traps
    cCellVision.generateTrainingSetTimelapse(cTimelapseOut,step_size,@(CSVM,image) createImFilterSetCellTrapStackBF(CSVM,image));
else
    cCellVision.negativeSamplesPerImage=15000; %set to 750 ish for traps
    cCellVision.generateTrainingSetTimelapse_wholeIm(cTimelapseOut,step_size,@(CSVM,image) createImFilterSetCellTrapStackBF(CSVM,image));
end
toc
%% Guess the cost/gamma parameters
cCellVision.trainingParams.cost=2
cCellVision.trainingParams.gamma=1
%%
cmd='-s 2 -w0 1 -w1 1 -w2 1 -v 5 -c ';
step_size=80;
cCellVision.runGridSearchLinear(step_size,cmd);
%%
step_size=6;
cCellVision.trainingParams.cost=1;
cmd = ['-s 2 -w0 1 -w1 1 -w2 1 -c ', num2str(cCellVision.trainingParams.cost)];
tic
cCellVision.trainSVMLinear(step_size,cmd);toc
%%
%%

step_size=3;
cCellVision.generateTrainingSet2Stage(cTimelapse,step_size);
%%
step_size=300;
cmdin='-t 2 -w0 1 -w1 1';
cCellVision.runGridSearch(step_size,cmdin);
%%
cCellVision.trainingParams.cost=1;
cCellVision.trainingParams.gamma=1;

%%
step_size=50;
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
num_frames=[1 250];
cCellVision.cTrap.Prior=.8;
cCellVision.cTrap.thresh=1.1;
cCellVision.cTrap.thresh_first=.8;
cCellVision.cTrap.objective=60

cTimelapse.identifyTrapLocations(cCellVision,display,num_frames);
cTimelapse.trackTrapsThroughTime();



%%
[d_imCenters, d_imEdges]=cTimelapse.identifyCellCentersTrap(cCellVision,timepoint,traps,[],[]);
%%
% for i=1:45
i=15
tp=1
trap_im=cTimelapse.returnSegmenationTrapsStack(i,tp);
% trap_im=cDictionary.cTrap(1).image(:,:,1);
tic
[p_im d_im]=cCellVision.classifyImage2Stage(trap_im{1},[]);toc
d_imCenters=d_im(:,:,1);
d_im=d_im(:,:,2);
figure(5);imshow(medfilt2(d_im),[]);impixelinfo;colormap(jet)
tim=medfilt2(d_im);
bwCell=tim<-1;
maskStart=(p_im==1);
maskLabel=bwlabel(maskStart);
bwl=bwlabel(bwCell);
maskStart=zeros(size(maskStart));
for i=1:max(maskLabel(:))
    t=max(bwl(maskLabel==i));
    if t>0
        maskStart(bwl==t)=1;
    end
    maskStart(maskLabel==i)=1;
end
tic
figure(12);imshow(maskStart,[]);title('Mask Start')

logisticIm=1./(1+exp(-tim));
figure(9);imshow(logisticIm,[]);colormap(jet)
tic
% bw=activecontour(b,maskStart,10,'Edge','ContractionBias',-.1,'SmoothFactor',0);toc
bw=activecontour(logisticIm,maskStart,5,'Chan-Vese','ContractionBias',-.2,'SmoothFactor',0);
bw=imfill(bw,'holes');toc
drawnow
figure(6);imshow(bw,[]);title('Cell End')
maskStart=bw;
bVar=[];
%%
se3=cCellVision.se.se3;
se1=cCellVision.se.se1;
se6=strel('disk',6);
alpha=.1;mu=0.1;
iterations=100;
beta=.7;gamma=10;kappa=-.5;
wl=10;
we=5;
wt=.1;
bwlN=bwlabel(maskStart>0);
pInit=(bwlN==2);
p=imclose(pInit,se6);
% p=bwmorph(p,'majority');
D = bwdist(~p);
D = -D;
D(~p) = -Inf;
figure(546);imshow(D,[]);
L = watershed(D);
figure(545);imshow(L,[]);
bwlN=bwlabel(p);
if max(L(:))>1
    lPerim=(L==0);
    bwP=imdilate(bwperim(p),se1);
    bwLNotP=sum(lPerim(~bwP));
    %only separate if things are barely joined
    if sum(lPerim(:)) > (2*pi*bwLNotP)*1.5
        pInit=L==4;
        p=pInit;
    end
%     disp('Two Cells Joined')
end
pInit=imdilate(pInit,se3);
figure(1);imshow(pInit,[]);
p=bwmorph(pInit,'remove');
[pr pc]=find(p>0);
props=regionprops(pInit);
nseg=24;
cirrad=sqrt(sum(pInit(:))/pi);
cirrad=cirrad*1.3; %radius buffering in case cell is elliptical
circen=props.Centroid;

figure(15);imshow(p,[]);
%
temp_im=logisticIm;
temp_im=zeros(size(temp_im))>0;
x=circen(1,1);y=circen(1,2);r=cirrad(1);
x=double(x);y=double(y);r=double(r);
if r<11
    theta = -.1 : (2 * pi / nseg) : (2 * pi);
elseif r<18
    theta = 0 : (2 * pi / nseg/1.3) : (2 * pi);
else
    theta = 0 : (2 * pi / nseg/1.8) : (2 * pi);
end
pline_x = round(r * cos(theta) + x);
pline_y = round(r * sin(theta) + y);
loc=find(pline_x>size(temp_im,2) | pline_x<1 | pline_y>size(temp_im,1) | pline_y<1);
pline_x(loc)=[];pline_y(loc)=[];
segLoc=[pc pr];
bIm=zeros(size(p));
segPts=[];
for i=1:length(pline_x)
    pt=[pline_x(i) pline_y(i)];
    [d ]=pdist2(segLoc,pt,'euclidean');
    [v loc]=min(d);
    segPts(i,:)=segLoc(loc(1),:);
    bIm(segPts(i,2),segPts(i,1))=1;
end
figure(123);imshow(bIm,[]);
xs=segPts(:,1);
ys=segPts(:,2);
% bb=5
% xs=pc(1:bb:end)';
% ys=pr(1:bb:end)';
% bim=zeros(size(b));
% for i=1:length(xs)
% bim(ys(i),xs(i))=1;
% end
% figure;imshow(b,[]);
% [xs ys]=getpts;
image=logisticIm;

figure(26);tic
image(:,1)=0.5;
image(:,end)=0.5;
image(1,:)=0.5;
image(end,:)=0.5;

[bVar,bw]=snakeIterate(bVar,image,xs',ys',alpha,beta,gamma,kappa,wl,we,wt,iterations);toc

% cTimelapse.cTimepoint(timepoint).trapInfo(trap(k)).segCenters=segCenters{k};

% figure(5);imshow(bw,[]);
im=trap_im{1}(:,:,1);
im(bw>0)=im(bw>0)*2.0;
figure(8);imshow(im,[],'InitialMagnification',200);pause(.1)
%%

% run GVF
tic;
[u,v] = GVF(logisticIm, alpha, mu, iter);
t=toc;

fprintf('Computing GVF uses %f seconds \n',t);

figure;
imshow(logisticIm);
hold on;
quiver(u,v);
axis ij off;
% end
%%
for i=1:25
% i=4
trap_im=cTimelapseOut.returnSegmenationTrapsStack(i,19);
im=trap_im{1}(:,:,1);
% im=min(trap_im{1}(:,:,1:2:3),[],3);
tim=im;

% edgeIm=edge(tim,'canny');
% figure(123);imshow(edgeIm,[]);
% tim=min(trap_im{1},[],3);

thresh=min(tim(:))+200*std(tim(:))/mean(tim(:));

% 
tim1=tim>thresh;

[gim gdir]=imgradient(tim,'CentralDifference');
gim=abs(gim);
fG=[1 0 0 0 0  1];
hx=imfilter(tim,fG,'replicate');
hy=imfilter(tim,fG','replicate');
gim=(hx.^2 + hy.^2).^.5;

ngim=gim/1;
timS=stdfilt(tim,true(11));
timD=tim+ngim-timS;
thresh=mean(timD(:))-.35*std(timD(:));
tim2=timD<thresh;
props=bwpropfilt(tim2,'area',[250 10000]);
figure(4);imshow(timD,[]);impixelinfo

figure(5);imshow(tim2,[])

tim3=bwmorph(props,'skel',Inf);
tim3=imerode(props,se1);
figure(6);imshow(props,[])

figure(7);imshow(tim3,[]);
pause(2);
end
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
trap1 = cTimelapseOut.returnSegmenationTrapsStack(11,cTimelapse.timepointsToProcess(19));
figure(12);imshow(image(:,:,2),[]);impixelinfo

%%
tic
% image=trap_im;
features=cCellVision.createImFilterSetCellTrapStackDIC(trap1{1});
image=trap1{1};
toc
im_feat=reshape(features,size(image,1),size(image,2),size(features,2));
    
for i=1:size(im_feat,3)
    figure(11);imshow(im_feat(:,:,i),[],'InitialMagnification',100);title(int2str(i));
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
