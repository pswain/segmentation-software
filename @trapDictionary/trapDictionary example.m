%% Example for the trapDictionary class
% 
% cTimelapse=timelapseTraps;
% cTimelapse.loadcTimelapse;

%% Example for timelapseTraps class

folder='/Users/mcrane/TimelapseImages'
cTimelapse=timelapseTraps();
cCellVision=cellVision();
searchString{1}='DIC';
searchString{2}='GFP';
cTimelapse.loadTimelapse(searchString);

% Select the traps  
cCellVision.selectTrapTemplate(cTimelapse)
%%  identify traps throughput the timelapse
display='all' %'all' or 'cc' or 'images' or 'none'
frames=[150 300];
cCellVision.cTrap.Prior=5;
cCellVision.cTrap.thresh=2;
cCellVision.cTrap.thresh_first=.9;

cTimelapse.identifyTrapLocations(cCellVision,display,frames);
cTimelapse.trackTrapsThroughTime();
%% Add traps using the secondary channel to determine the ground truth
% Uses the fluorescent channel (secondary), and thresholds it to determine
% a simple ground truth label
cDictionary=trapDictionary
channels=[1 2];
radius=[6 16];
cDictionary.addAllTrapsLabelSecondary(cTimelapse,channels,'center',radius);
%%
cDictionary.saveDictionaryVision(cCellVision);
% %% Add selected traps to the dictionary
% % Adding all traps may make too large a variable, so just add a few traps
% % to the dictionary
% 
% cDictionary=trapDictionary
% cDictionary.addTrapLabelSecondary(cTimelapse,5);
% cDictionary.addTrapLabelSecondary(cTimelapse,7);
% cDictionary.addTrapLabelSecondary(cTimelapse,14);
% 
% cDictionary.saveDictionary(cCellVision);










%%
i=1


trapTimelapse=cTimelapse.returnSingleTrapTimelapse(1,2);
%             trapTimelapse_DIC=cTimelapse.returnSingleTrapTimelapse(i,channels(1));

trapTimelapse=double(trapTimelapse);
if i==1
    max_TL=max(trapTimelapse(:));
end
trapTimelapse=trapTimelapse/max_TL;
if i==1
    thresh=graythresh(trapTimelapse);
end
%%
se2=strel('disk',2);
se=strel('disk',2);
trapTimepoint=trapTimelapse(:,:,263);
t_im=trapTimepoint;
trapTimepoint=imfilter(trapTimepoint,fspecial('disk',2),'replicate');
                                t_im=stdfilt(t_im,true(5));
[accum, circen, cirrad] = CircularHough_Grd(t_im, [4 15],max(t_im(:))*.001,5,1);
%                 [accum, circen2] = CircularHough_Grd(trapTimepoint, [6 14],max(trapTimepoint(:))*.01,8,1);
%                 circen=[circen; circen2];
circen=round(circen);
% loc=find(cirrad<7);
% circen(loc,:)=[];


bw=zeros(size(trapTimepoint,1),size(trapTimepoint,2));
for circles=1:size(circen,1)
    bw(circen(circles,2),circen(circles,1))=1;
end
bw_cells=im2bw(trapTimepoint,thresh);
bw_cells=imdilate(bw_cells,se2);
%                 bw=imclearborder(bw);
%                 bw_dist=-bwdist(~bw);
%                 bw_dist(~bw)=-Inf;
%                 bw_w=watershed(bw_dist);
%                 bw=bwmorph(bw_w>1,'shrink',Inf);
bw=imdilate(bw,se);
bw=bw&bw_cells;
tempy=trapTimepoint;
tempy(bw)=tempy(bw)*2;
figure(1);imshow(tempy,[]);
figure(2);imshow(trapTimepoint,[0 1]);
figure(3);imshow(accum,[]);pause(.1);

figure(4);imshow(bw_cells,[]);
figure(5);imshow(t_im,[])