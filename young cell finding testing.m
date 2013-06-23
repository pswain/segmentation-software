cTimelapse.correctSkippedFramesInf;
rad=cTimelapse.extractedData(1).radius;

newRad=[];
growth=[];
trapNum=[];
for i=1:size(rad,1);
    loc=rad(i,:)>0;
    temp=smooth(rad(i,loc),4,'moving');
    newRad(i,1:sum(loc))=temp;
    tempy=temp(1:2:end);
    growth(i,1:length(tempy)-1)=diff(tempy)./temp(1:2:end-2);
    trapNum(i)=cTimelapse.extractedData(1).trapNum(i);
end

cellNum=cTimelapse.extractedData(1).cellNum;
% growth=diff(newRad(:,1:3:end),1,2)./newRad(:,3:3:end);


figure(2);plot(mean(growth,1))
% figure(3);plot((growth)')
%%
youngG=growth(:,1:3);
figure(4);ksdensity(youngG(youngG>0));
figure(5);ksdensity(youngG(:));
temp=max(youngG,[],2);
figure(6);ksdensity(temp(:));
ksdensity(temp(:))
%%
newThresh=.1
sum(max(youngG,[],2)>newThresh)

newCells=max(youngG,[],2)>newThresh;
locs=find(newCells);

%%
for i=1:sum(newCells);
    figure(10);plot(newRad(locs(i),:));axis([0 350 4 15])
    %axis([0 50 0 .5])
    pause(1)
end
%%
figure(10);plot(growth(locs,:)');axis([0 150 0 .5])

sum(rad(newCells,:)>0,2)

figure(10);plot(std(growth(locs,:),1));axis([0 150 0 .5])

%%
[r c]=find(growth(locs,50:end)>newThresh)
%%
radNewCells=newRad(newCells,:);

figure(1);imshow(radNewCells,[]);colormap(jet);impixelinfo
%%
ksdensity(temp(:))
%%
youngG=growth(:,1:3);

newThresh=.09;
sum(max(youngG,[],2)>newThresh);
maxG=max(youngG,[],2)';
newCells=maxG>newThresh;
locs=find(trapNum==18);
sum(newCells(locs))

%%
cTimelapse.cellsToPlot=sparse(zeros(size(cTimelapse.cellsToPlot)));
youngG=growth(:,1:3);
youngR=newRad(:,1:2);
maxG=max(youngG,[],2)';
minR=min(youngR,[],2)';
newThresh=.09;
newThreshlo=.07;

newCells=(maxG>newThresh)|(maxG>newThreshlo & minR<=6);
for i=1:max(trapNum)
    loc=trapNum==i;
    t=cellNum(loc);
    t=t(newCells(loc));
    cTimelapse.cellsToPlot(i,t)=1;
end
sum(newCells(:))

cTrapDisplayPlot(cTimelapse,[]);
%%
youngG=growth(:,1:3);
youngR=newRad(:,1:2);
maxG=max(youngG,[],2)';
minR=min(youngR,[],2)';
newThresh=.09;
newThreshlo=.07;

newCells=(maxG>newThresh)|(maxG>newThreshlo & minR<=6);
locs=find(newCells);
l=find(trapNum(locs)==1);
youngG(locs(l),:);
cellNum(locs(l),:);
length(l)