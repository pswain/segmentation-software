uiload();
cExperiment.correctSkippedFramesInf
cExperimentFeb112=cExperiment;
clear cExperiment;
%%
plot(mean(cExperimentFeb112.cellInf(2).mean)');shg
%%
channel=2;
switchTimeFeb112=1;
endTimeFeb112=330;
temp=cExperimentFeb112.cellInf(1).median;
temp=temp(:,1:size(temp,2));
temp=temp(:,1:100);

cellsPresentFeb112=min(temp')>0;

temp=cExperimentFeb112.cellInf(2).median;
temp=temp(:,1:endTimeFeb112);
cellsPresent2=min(temp')>-1;
cellsPresentFeb112=cellsPresentFeb112&cellsPresent2;

cellInfFeb112=cExperimentFeb112.cellInf(channel);
cellInfFeb112.mean=cellInfFeb112.mean(cellsPresentFeb112,:);
cellInfFeb112.median=cellInfFeb112.median(cellsPresentFeb112,:);
cellInfFeb112.std=cellInfFeb112.std(cellsPresentFeb112,:);
cellInfFeb112.max5=cellInfFeb112.max5(cellsPresentFeb112,:);
cellInfFeb112.radius=cellInfFeb112.radius(cellsPresentFeb112,:);

%%
figure(10);
plot(median(cellInfFeb112.mean)')
%%
figure(12);
tempData=cellInfFeb112.radius(:,switchTimeFeb112:endTimeFeb112);
% tempData=tempData./cellInfFeb112.median(:,switchTimeFeb112:endTimeFeb112);
plot(mean(cExperimentFeb112.cellInf(2).median(cellsPresentFeb112,:))')
pause(1)
temp=cExperimentFeb112.cellInf(2).median(cellsPresentFeb112,:);
plotData=[]
for i=1:size(cExperimentFeb112.cellInf(2).median,2)
    loc=(cExperimentFeb112.cellInf(1).median(:,i)>0) & cellsPresentFeb112';
    plotData(i)=mean(cExperimentFeb112.cellInf(2).radius(loc,i));
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
temp=cellInfFeb112.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%

%% Pretty Kymograph
temp=cExperimentFeb112.cellInf(2).median(cellsPresentFeb112,:);
m=mean(temp(:,end-100:end),2);
[val loc]=sort(m,'descend');
loc=1:length(loc);
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
end
figure(11);imshow(temp,[]);colormap(jet);
%%
temp=cExperimentFeb112.cellInf(1).max5(cellsPresentFeb112,100:end);
figure(11);imshow(temp,[]);colormap(jet);

%%
temp=cExperimentFeb112.cellInf(1).mean(cellsPresentFeb112,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentFeb112.cellInf(channel).mean,2);
for cell=1:size(cExperimentFeb112.cellInf(channel).mean,1)
    meancell=cExperimentFeb112.cellInf(channel).mean(cell,:);
    max5cell=cExperimentFeb112.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 1.3e3]);
    pause(2);
end
