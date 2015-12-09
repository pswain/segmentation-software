fileNames=[];
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/3_3_6um.mat';
%fileNames{end+1}='/Users/iclark/Documents/Shampoo data/4_3_6um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/20_3_10um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/23_3_6um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/24_3_6umCup2.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/25_2_2um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/25_3_50um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/26_2_10um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/26_3_2um.mat';
fileNames{end+1}='/Users/iclark/Documents/Shampoo data/27_2_10um.mat';

%fileNames{end+1}='/Users/mcrane2/OneDrive/timelapses/Dandruff/Feb 27 - 10uM ZpT switch at 5h and back at 10h/cExperiment.mat';
%fileNames{end+1}='/Users/mcrane2/OneDrive/timelapses/Dandruff/Mar 3 - 6uM ZpT switch at 5h/cExperiment.mat';
%fileNames{end+1}='/Users/mcrane2/OneDrive/timelapses/DR robin/28-Aug 2014 (DR w cont pregrown DR)/cExperiment.mat';
close all
motherDurParams=[];
data=[];
addpath('dandruff');
for fileIndex=1:length(fileNames)
    fileIndex
    currFileName=fileNames{fileIndex};
    data{fileIndex}=extractDandruffData(currFileName);
   
end

data{1}
data{2}
%%

kdBirths=[];
tps=-1:.1:10;
bw=1.51;
for expNum=1:length(data);
for tp=1:size(data{expNum}.cumsumBirths,2)
    temp=ksdensity(data{expNum}.cumsumBirths(:,tp)',tps,'bandwidth',bw);
    kdBirths(:,tp)=temp;
end

nVal=num2str(size(data{expNum}.cumsumBirths,1));
figure(expNum);imshow(flipud(kdBirths),[]);colormap(jet)
name=fileNames{expNum};
k=strfind(fileNames{expNum},'/');
name=name(k(end)+1:end-4);
name(strfind(name,'_'))='-';
title([name ': ' nVal ' - cells']);
xlabel('Time')
ylabel('Cumulative births')

%Save the image as a jpg
savePath=fileNames{expNum};
saveas(figure(gcf),[savePath(1:k(end)) name '.jpg']);
end
















%%
i=1;
figure(1);
x=data{i}.birthsPerSeg(1,:);
x=x+.05*randn(size(x));
y=data{i}.birthsPerSeg(2,:);
y=y+.05*randn(size(y));
scatter(x,y)


[xg, yg] = meshgrid(0 : 0.1 : 1);
wg = griddata(x,y,xg,yg);
contour(xg,yg,wg);
%%
[X,Y] = meshgrid(x,y);
Z = peaks(X,Y);
v = [1,1];

figure(2);contour(X,Y,Z,v)
%%
figure(1);
% [x pts]=ksdensity(data{1}.birthsPerSeg');
[x1 pts]=ksdensity(data{1}.birthsPerSeg(1,:)');
[x2 pts]=ksdensity(data{1}.birthsPerSeg(2,:)',pts);

x=[x1; x2];
plot(pts,x);
legend('Pre','During');
figure(2);
% hist(data{2}.birthsPerSeg')
[x1 pts]=ksdensity(data{2}.birthsPerSeg(1,:)',pts);
[x2 pts]=ksdensity(data{2}.birthsPerSeg(2,:)',pts);
[x3 pts]=ksdensity(data{2}.birthsPerSeg(3,:)',pts);

x=[x1; x2;x3];
plot(pts,x);

legend('Pre','During','Post');

%%
sizeC(sizeC==0)=NaN;
figure;plot(sizeC'.^3*4/3);
legend(leg)
%% distributions of the sizes

plotDataBud=[];
plotDataNoBud=[];
batchOrNot='Device';
pts=7:.1:10;
leg=[];
for expIndex=1:length(data)
    if strcmp(data(expIndex).expType,batchOrNot)
        plotDataBud=[];
plotDataNoBud=[];

        t=(data(expIndex).ssData.maltLvl4h);
        y=data(expIndex).ssTimeToBud;
        temp=data(expIndex).ssData.nPreDaught;
        y=isnan(y) | (y > (nanmedian(y) +3*12));
        
        t1=t(y);
        plotDataNoBud(end+1:end+length(t1))=t1;
        t1=t(~y);
        plotDataBud(end+1:end+length(t1))=t1;
        [x pts]=ksdensity(plotDataBud);
[x2 pts]=ksdensity(plotDataNoBud,pts);
figure(12);plot(pts,[x; x2]);
legend('Budding','Not Budding')
pause(2)
    end
end
%%
[x pts]=ksdensity(plotDataBud);
[x2 pts]=ksdensity(plotDataNoBud,pts);
figure;plot(pts,[x; x2]);
legend('Budding','Not Budding')

%% plot the fraction budding
plotData=[];
leg=[];
for expIndex=1:length(data)
    t=(data(expIndex).fractionBudding);
    plotData(expIndex,1:length(t))=t;
    leg{end+1}=data(expIndex).legStr;
end
xTime=0:1:(size(plotData,2)-1);
xTime=xTime/12;
figure;plot(xTime,plotData');
legend(leg)

axis([0 12 0 1]);

xlabel('Time (h)')
ylabel('Fraction Budding')
%%
%%