

%% This functin is to identify the newborn cells

trap=3;
i=3;
maxCell=cTimelapse.cTimepoint(1).trapMaxCell(trap);
cell=struct();
for i=1:length(cTimelapse.timepointsProcessed)
    trapInfo=cTimelapse.cTimepoint(i).trapInfo(trap);
    for cellNum=1:length(trapInfo.cellLabel)
        cell(cellLabel(cellNum)).radius(i)=trapInfo.cell(cellNum).cellRadius;
        cell(cellLabel(cellNum)).center(i)=trapInfo.cell(cellNum).cellCenter;
        cell(cellLabel(cellNum)).radius(i)=trapInfo.cell(cellNum).cellRadius;
    end
end
%%
cTimelapse.trackCells;

%%
params.fraction=.1; %fraction of timelapse length that cells must be present or
params.duration=5; %number of frames cells must be present
params.framesToCheck=length(cTimelapse.timepointsProcessed);
params.framesToCheckEnd=1;

cTimelapse.automaticSelectCells(params);


cTimelapse.extractCellParamsOnly;
sum(cTimelapse.cellsToPlot(:))

sum([cTimelapse.cTimepoint(1).trapMaxCell])
%%
cTimelapse.correctSkippedFramesInf;
rad=cTimelapse.extractedData(1).radius;

newRad=[];
growth=[];
trapNum=[];
xloc=[];yloc=[];
index=1;
for i=1:size(rad,1);
    loc=rad(i,:)>0;
    if sum(loc)>0
        temp=smooth(rad(i,loc),4,'moving');
        newRad(index,1:sum(loc))=temp;
        tempy=temp(1:end);
        growth(index,1:length(tempy)-1)=diff(tempy)./temp(1:end-1);
%                 growth(index,1:length(tempy)-1)=diff(tempy)./temp(1:2:end-2);

        trapNum(index)=cTimelapse.extractedData(1).trapNum(i);
        xloc(index,1:sum(loc))=cTimelapse.extractedData(1).xloc(i,loc);
        yloc(index,1:sum(loc))=cTimelapse.extractedData(1).yloc(i,loc);
        index=index+1;
    end
    
end

duration=sum(newRad>0,2);
cellNum=cTimelapse.extractedData(1).cellNum;
% growth=diff(newRad(:,1:3:end),1,2)./newRad(:,3:3:end);

% figure(2);plot(mean(growth,1))
% figure(3);plot((growth)')
%%
xspeed=diff(xloc,1,2);
yspeed=diff(yloc,1,2);
t=xloc==0;
t=t(:,1:end-1);
xspeed(t)=0;
yspeed(t)=0;

t=xloc==0;
t=t(:,2:end);
xspeed(t)=0;
yspeed(t)=0;

p=[]
for i=1:size(xspeed,2)
    temp=xspeed(:,i);
    temp=abs(temp(abs(temp)>0));
    p(i)=mean(temp);
end
% figure(2);plot(p)
%%
clc
youngG=growth(:,1:4);
youngR=newRad(:,1:4);
maxG=max(youngG,[],3)';
minR=min(youngR,[],3)';

meanx=[];meany=[];
for i=1:size(xspeed,1)
    temp=xspeed(i,1:duration(i)-1);
    s=min(length(temp),5);
    meanx(i)=mean(temp(1:s));
    temp=yspeed(i,1:duration(i)-1);
    meany(i)=mean(temp(1:s));

end
% meanx(duration==0)=0;
% meany(duration==0)=0;
% meanx=mean(xspeed(:,1:10),2);
% meany=mean(yspeed(:,1:10),2);

speed=sqrt(meanx.^2+meany.^2)';
features=[max(growth(:,1:4),[],2) mean(growth(:,1:3),2) min(newRad(:,1:4),[],2) mean(newRad(:,1:4),2) speed duration];

% features=zscore(features);
features=features-repmat(min(features),[size(features,1) 1]);
features=features./repmat(max(features),[size(features,1) 1]);

[pc,score,latent,tsquare] = princomp(features);
features=score(:,1:4);

% id=kmeans(features,2,'replicates',5);
options=statset('MaxIter',400);
obj = gmdistribution.fit(features,2,'SharedCov',false,'replicates',30,'Options',options);
id=posterior(obj,features);

new=id(:,1)>id(:,2);
id=new+1;

% max([sum(id==2) sum(id==1)])
% max([sum(id==2 & newCells) sum(id==1 & newCells)])
% min([sum(id==2 & ~newCells) sum(id==1 & ~newCells)])

sum(new)/length(new)
sum(id==1)/length(id)
cumsum(latent)./sum(latent) 
% obj.AIC
%%
[x1 xi]=ksdensity(features(id==1),-1:.01:2);
[x2]=ksdensity(features(id==2),xi);
% [x3]=ksdensity(features(id==3),xi);

b=[x1 ;x2];
figure(4);plot(xi,b');

%%
youngG=growth(:,1:3);
figure(4);ksdensity(youngG(youngG>0));
figure(5);ksdensity(youngG(:));
temp=max(youngG,[],2);
figure(6);ksdensity(temp(:));
ksdensity(temp(:))

figure(6);ksdensity(mean(youngG,2));


%%
cTimelapse.cellsToPlot=sparse(zeros(size(cTimelapse.cellsToPlot)));

if sum(id==1)/length(id)>.5
    newCells=id==1;
else
    newCells=id==2;
end
for i=1:max(trapNum)
    loc=trapNum==i;
    t=cellNum(loc);
    t=t(newCells(loc));
    cTimelapse.cellsToPlot(i,t)=1;
end
sum(newCells(:))

cTrapDisplayPlot(cTimelapse,[]);



    