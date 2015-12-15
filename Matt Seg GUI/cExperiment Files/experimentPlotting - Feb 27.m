uiload();
cExperiment.correctSkippedFramesInf
cExperimentFeb27=cExperiment;
clear cExperiment;
%% gfp
plot(mean(cExperimentFeb27.cellInf(2).mean)')
fig
%% cy5
plot(mean(cExperimentFeb27.cellInf(3).mean)')
fig
%% select cells that stay
channel=2;
switchTimeFeb27=30;
endTimeFeb27=switchTimeFeb27+6.5*12;

temp=cExperimentFeb27.cellInf(1).mean;
temp=temp(:,1:endTimeFeb27);
cellsPresentFeb27=min(temp')>0;

temp=cExperimentFeb27.cellInf(2).median;
temp=temp(:,30:endTimeFeb27);
cellsPresent2=max(temp')>1e3;
cellsPresentFeb27=cellsPresentFeb27&cellsPresent2;

cellInfFeb27=cExperimentFeb27.cellInf(channel);
cellInfFeb27.mean=cellInfFeb27.mean(cellsPresentFeb27,:);
cellInfFeb27.median=cellInfFeb27.median(cellsPresentFeb27,:);
cellInfFeb27.std=cellInfFeb27.std(cellsPresentFeb27,:);
cellInfFeb27.max5=cellInfFeb27.max5(cellsPresentFeb27,:);
cellInfFeb27.radius=cellInfFeb27.radius(cellsPresentFeb27,:);

%%
figure(10);
plot(median(cellInfFeb27.median)')
%% Plot data
figure(11);
tempData=cellInfFeb27.median(:,switchTimeFeb27:endTimeFeb27);
tempPlot=mean(tempData)';
error=std(tempData)';
error=error/sqrt(size(tempData,1));
x=5:5:size(tempData,2)*5;
x=x/60;
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Mean of median GAL10::GFP induction after 2.5 hours (n~170)');
xlabel('time (hours)');ylabel('Median Cell Fluorescence (AU)');

%%
temp=cellInfFeb27.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%
temp=cExperimentFeb27.cellInf(2).mean(cellsPresentFeb27,1:endTimeFeb27);
figure(11);imshow(temp,[]);colormap(jet);

%%
temp=cExperimentFeb27.cellInf(1).mean(cellsPresentFeb27,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);
%% Pretty Kymograph
temp=cellInfFeb27.median(:,switchTimeFeb27:endTimeFeb27);
m=mean(temp(:,end-20:end),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
end
% temp2(8:9,:)=[];
figure(11);imshow(temp2,[0 33000]);colormap(jet);

%% 5 plots showing random cells
tempD=temp2([7 36 72 109 90],:)';
figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([0 7 0 30e3]);
%% Pretty Kymograph normalized to single cell max
temp=cellInfFeb27.median(:,switchTimeFeb27:endTimeFeb27);
m=mean(temp(:,end-20:end),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
    temp2(i,:)=temp2(i,:)/max(temp2(i,:));
end
% temp2(8:9,:)=[];
figure(11);imshow(temp2,[ ]);colormap(jet);

%%

%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentFeb27.cellInf(channel).mean,2);
for cell=1:size(cExperimentFeb27.cellInf(channel).mean,1)
    meancell=cExperimentFeb27.cellInf(channel).mean(cell,:);
    max5cell=cExperimentFeb27.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 60e3]);
    pause(2);
end
