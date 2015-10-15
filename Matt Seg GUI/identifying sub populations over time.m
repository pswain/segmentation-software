

%% This functin is to identify the newborn cells

cTimelapse.trackCells;

params.fraction=.1; %fraction of timelapse length that cells must be present or
params.duration=5; %number of frames cells must be present
params.framesToCheck=length(cTimelapse.timepointsProcessed);
params.framesToCheckEnd=1;

cTimelapse.automaticSelectCells(params);
cTimelapse.extractCellParamsOnly;
sum(cTimelapse.cellsToPlot(:))
sum([cTimelapse.cTimepoint(1).trapMaxCell])
%% Create the features for the classification
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
        temp=smooth(rad(i,loc),1,'moving');
        newRad(index,1:sum(loc))=temp;
        
        tempy=temp(1:end);
        growth(index,1:length(tempy)-1)=diff(tempy)./temp(1:end-1);
    
%         temp=smooth(rad(i,loc),5,'moving');
%         tempy=temp(1:2:end);
%         b=diff(tempy)./tempy(1:end-1);
%         growth(index,1:2:length(b)*2)=b;
%         tempy=temp(2:2:end);
%         b=diff(tempy)./tempy(1:end-1);
%         growth(index,2:2:length(b)*2)=b;

        trapNum(index)=cTimelapse.extractedData(1).trapNum(i);
        xloc(index,1:sum(loc))=cTimelapse.extractedData(1).xloc(i,loc);
        yloc(index,1:sum(loc))=cTimelapse.extractedData(1).yloc(i,loc);
        index=index+1;
    end
    
end


%% remove cells that have been there a long time

duration=sum(newRad>0,2);
cellNum=cTimelapse.extractedData(1).cellNum;

del=duration>50;
growth(del,:)=[];
xloc(del,:)=[];
yloc(del,:)=[];
duration(del)=[];
cellNum(del)=[];
%% Create the speed by smoothing locations over time.

xspeed=diff(xloc,1,2);
yspeed=diff(yloc,1,2);
t=xloc==0;
t=t(:,1:end-1);xspeed(t)=0;yspeed(t)=0;

t=xloc==0;
t=t(:,2:end);xspeed(t)=0;yspeed(t)=0;

meanx=[];meany=[];
for i=1:size(xspeed,1)
    temp=xspeed(i,1:duration(i)-1);
    temp=smooth(temp,3,'moving');
    meanx(i,1:length(temp))=temp;
    temp=yspeed(i,1:duration(i)-1);
    temp=smooth(temp,3,'moving');
    meany(i,1:length(temp))=temp;
end
% 
speed=sqrt(meanx.^2+meany.^2);
%% Create the actual feature vector that is used to classify cell stages as young or old
index=1;
% features=zeros(sum(duration),4*2);
features=[];
ss=6;
cellNumF=[];trapNumF=[];
for i=1:size(xspeed,1)
    for j=1:1:duration(i)-ss-1
%         if j<3 | j>7
            features(index,:)=[abs(mean(xspeed(i,j:j+ss))) abs(mean(yspeed(i,j:j+ss))) ...
                (max(newRad(i,j:j+ss)) - min(newRad(i,j:j+ss))) ...
                median(newRad(i,j:j+ss)) min(newRad(i,j:j+ss)) ...
                max(growth(i,j:j+ss)) mean(abs(growth(i,j:j+ss))) mean((growth(i,j:j+ss)))...
                sqrt(mean(xspeed(i,j:j+ss)).^2 + mean(yspeed(i,j:j+ss)).^2) mean(speed(i,j:j+ss))];
            
            % ...
            %             mean(sqrt((xspeed(i,j:j+ss)).^2 + (yspeed(i,j:j+ss)).^2))
            %             %             mean(abs(meanx(i,j:j+ss))) ...
            %             abs(mean(xspeed(i,j:j+ss))) ... %max(abs(meanx(i,j:j+ss))) ...
            %             %             mean(abs(meany(i,j:j+ss))) ... %max(abs(meany(i,j:j+ss))) ...
            %             abs(mean(yspeed(i,j:j+ss))) ...
            %             mean(newRad(i,j:j+ss)) ...
            %             min(newRad(i,j:j+1)) ...
            %             growth(i,j) ...
            %             mean(growth(i,j:j+ss)) ... % max(growth(i,j:j+ss)) ...
            % %             mean(speed(i,j:j+ss)) ...
            %             sqrt(mean(xspeed(i,j:j+ss)).^2 + mean(yspeed(i,j:j+ss)).^2)];
            cellNumF(index)=cellNum(i);
            trapNumF(index)=trapNum(i);
            index=index+1;
%         end
    end
end

%
% features=zscore(features);
features=features-repmat(min(features),[size(features,1) 1]);
features=features./repmat(max(features),[size(features,1) 1]);
[pc,score,latent,tsquare] = princomp(features);
cumsum(latent)./sum(latent)
%%
loc1=zeros(size(cellNumF));
loc2=zeros(size(cellNumF));
sL=5;
for trap=1:max(trapNumF)
    for cell=1:max(cellNumF(trapNumF==trap))
        loc=find(cellNumF==cell & trapNumF==trap);
        if ~isempty(loc)
            if length(loc)>12
                b=floor(length(loc)/3);
                loc1(loc(1:4))=1;
                loc1(loc(end-b+1:end))=1;
            else
                b=floor(length(loc)/3);
                loc1(loc(1:b))=1;
                loc1(loc(end-2*b:end))=2;
            end
        end
    end
end

training=features(loc1>0,:);
class=loc1(loc1>0);

nb=NaiveBayes.fit(training,class,'Distribution','mvmn','prior',[.1 .9])
%%
features=score(:,1);
% features=features.*repmat(latent(1:2)'/sum(latent),[size(features,1) 1]);
figure(123);ksdensity(score(:,1),-1:.01:2);title('First Prin Comp')

%%
figure(10);scatter(features(:,1),features(:,2),10,'.'); hold on
h = ezcontour(@(x,y)pdf(obj,[x y]),[-1.2 .6],[-.4 1.2]);
%%
% id=kmeans(features,2,'replicates',5);
options=statset('MaxIter',500);
obj = gmdistribution.fit(features,2,'SharedCov',false,'replicates',15,'Options',options);
id=posterior(obj,features);
post=id;
new=id(:,1)>id(:,2);
id=new+1;

sum(new)/length(new)
sum(id==1)/length(id)
% figure(123);ksdensity(features(:,2),-1:.01:2);
obj.AIC
%%
index=1;
postC=[];

% post=nb.posterior(features);
for trap=1:max(trapNumF(:))
    for cell=1:max(cellNumF(:))
        loc=find(cellNumF==cell & trapNumF==trap);
        if ~isempty(loc)
%             postC(index,1:length(loc))=post(loc);
            postC(index,1:length(loc))=post(loc);
            index=index+1;
        end
    end
end

t=[];
for i=1:size(postC,2)
    temp=postC(:,i);
    t(i)=mean(temp(temp>0));
end
figure(1232);plot(t');title('Mean probability a cell is in state 2')
%%
seq=[];states=[];
for i=1:size(postC,1);
    temp=postC(i,:);
    temp=temp(temp>0);
    temp=temp*10;
    temp=smooth(temp,7,'lowess')';
    temp(temp<0)=0;
    temp(temp>9)=9;
    seq{i}=floor(temp)+1;
    states{i}=(temp>5)+1;
end

trGuess=[.85 .15 ; ...
    .01 .99];

eGuess=[];
eGuess(1,:)=1.3.^(10:-1:1);
eGuess(1,:)=1:-.1:.1;

eGuess(1,:)=eGuess(1,:)./sum(eGuess(1,:));
eGuess(2,:)=.1:.1:1;
% eGuess(2,:)=1.2.^(1:1:10);
eGuess(2,:)=eGuess(2,:)./sum(eGuess(2,:));

[TRANS EMIS]=hmmtrain(seq,trGuess,eGuess,'Algorithm','Viterbi')
% [TRANS,EMIS] = hmmestimate(seq,states)
%%

%%
clc
for i=1:length(seq)
% i=79;
state=hmmdecode(seq{i},TRANS,EMIS);
% state=hmmdecode(seq{i},trGuess,eGuess);

seq{i}
figure(123);stem((state(1,:)>.5)+1); axis([0 100 0 2])
pause(.3)
end
(seq{i}<5)+1
% postC(i,1:10)*10
% state(1,1:10)*10
%%
% trGuess=[.8 .15 .05 ; ...
%     .1 .3 .6 ;...
%     .0 .2 .8];

eGuess=[];
% eGuess=ones(2,3)/3;
eGuess(1,:)=1.2.^(10:-1:1);
% eGuess(1,:)=1:-.1:.1;

eGuess(1,:)=eGuess(1,:)./sum(eGuess(1,:));

eGuess(2,:)=ones(1,10)/10;

eGuess(3,:)=.1:.1:1;
eGuess(3,:)=1.2.^(1:1:10);
eGuess(3,:)=eGuess(3,:)./sum(eGuess(3,:));

[TRANS EMIS]=hmmtrain(seq,trGuess,eGuess,'Algorithm','Viterbi')
%%
clc
i=30;
state=hmmdecode(seq{i},TRANS,EMIS);
state=hmmdecode(seq{i},trGuess,eGuess);

seq{i}
(state(1,:)>.5)+1
(seq{i}<6)+1
%%
figure(101);
h=gca;
for i=1:size(postC,1)
    temp=postC(i,:);
    l=find(temp>0);
    temp=temp(1:max(l)-0);
    %     temp=smooth(temp);
    %     temp=temp>.5;
    plot(h,abs(temp));axis([0 30 0 1]);title(int2str(i))
% stem(h,temp>.5);axis([0 30 0 1]);title(int2str(i))
    pause(1);
end
%%
figure(101);
h=gca;
i=78
    temp=postC(i,:);
    l=find(temp>0);
    temp=temp(1:max(l)-0);

    plot(h,abs(temp));axis([0 30 0 1]);title(int2str(i))
% stem(h,temp>.5);axis([0 30 0 1]);title(int2str(i))
    pause(1);

%%

            b=[abs(mean(xspeed(i,j:j+ss)))...
            abs(mean(yspeed(i,j:j+ss))) ...
            mean(newRad(i,j:j+ss)) ...
            min(newRad(i,j:j+1)) ...
            growth(i,j) ...
            mean(growth(i,j:j+ss)) ... 
            sqrt(mean(xspeed(i,j:j+ss)).^2 + mean(yspeed(i,j:j+ss)).^2)];














%%
cell=15;trap=1;
loc=find(cellNumF==cell & trapNumF==trap);
cellNumF(loc);
if length(loc)>20
   loc=loc(1:20);
end
id(loc)'
post(loc)





%%
loc=find(cellNum'==cell & trapNum==trap);


%%
loc=find(id==2);
trapNumF(loc(1))
cellNumF(loc(1))
%%
cTrapDisplayPlot(cTimelapse,[]);


%%
[x1 xi]=ksdensity(features(id==1),-1:.01:2);
[x2]=ksdensity(features(id==2),xi);
% [x3]=ksdensity(features(id==3),xi);

b=[x1 ;x2];
b=[x1];
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



    