uiload();
cExperiment.correctSkippedFramesInf
cExperimentFeb11=cExperiment;
clear cExperiment;
%%
plot(mean(cExperimentFeb11.cellInf(2).mean)');shg
%%
channel=2;
switchTimeFeb11=1;
endTimeFeb11=330;
temp=cExperimentFeb11.cellInf(1).median;
temp=temp(:,1:size(temp,2));
temp=temp(:,1:100);

cellsPresentFeb11=min(temp')>0;

temp=cExperimentFeb11.cellInf(2).median;
temp=temp(:,1:endTimeFeb11);
cellsPresent2=min(temp')>-1;
cellsPresentFeb11=cellsPresentFeb11&cellsPresent2;
cellsPresentFeb11(140:end)=0;

cellInfFeb11=cExperimentFeb11.cellInf(channel);
cellInfFeb11.mean=cellInfFeb11.mean(cellsPresentFeb11,:);
cellInfFeb11.median=cellInfFeb11.median(cellsPresentFeb11,:);
cellInfFeb11.std=cellInfFeb11.std(cellsPresentFeb11,:);
cellInfFeb11.max5=cellInfFeb11.max5(cellsPresentFeb11,:);
cellInfFeb11.radius=cellInfFeb11.radius(cellsPresentFeb11,:);

%%
figure(10);
plot(median(cellInfFeb11.mean)')
%%
figure(10);
tempData=cellInfFeb11.radius(:,switchTimeFeb11:endTimeFeb11);
% tempData=tempData./cellInfFeb11.median(:,switchTimeFeb11:endTimeFeb11);
plot(mean(cExperimentFeb11.cellInf(2).median(cellsPresentFeb11,:))')
pause(1)
temp=cExperimentFeb11.cellInf(2).radius(cellsPresentFeb11,:);
plotData=[]
for i=1:size(cExperimentFeb11.cellInf(2).median,2)
    loc=(cExperimentFeb11.cellInf(1).median(:,i)>0) & cellsPresentFeb11';
    plotData(i)=mean(cExperimentFeb11.cellInf(2).radius(loc,i));
end
tempPlot=plotData';
% tempPlot=median(tempData)';
error=std(tempData)';
error=error/sqrt(size(tempData,1));
x=5:5:size(tempData,2)*5;
x=x/60;
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Median HSP104::GFP expression (n~270)');
xlabel('time (hours)');ylabel('Median Cell Fluorescence (AU)');
axis([0 max(x) min(tempPlot)*.9 max(tempPlot)*1.1])
%%
temp=cellInfFeb11.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%

%% Pretty Kymograph
temp=cExperimentFeb11.cellInf(2).median(cellsPresentFeb11,:);
m=mean(temp(:,end-100:end),2);
[val loc]=sort(m,'descend');
loc=1:length(loc);
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
end
figure(11);imshow(temp,[]);colormap(jet);
%%
temp=cExperimentFeb11.cellInf(1).max5(cellsPresentFeb11,100:end);
figure(11);imshow(temp,[]);colormap(jet);

%%
temp=cExperimentFeb11.cellInf(1).mean(cellsPresentFeb11,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentFeb11.cellInf(channel).mean,2);
for cell=1:size(cExperimentFeb11.cellInf(channel).mean,1)
    meancell=cExperimentFeb11.cellInf(channel).mean(cell,:);
    max5cell=cExperimentFeb11.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 1.3e3]);
    pause(2);
end
