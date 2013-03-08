uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentFeb8=cExperiment;
clear cExperiment;
%%
plot(mean(cExperimentFeb8.cellInf(2).mean)')
fig
%%
plot(mean(cExperimentFeb8.cellInf(3).mean)')
fig
%%
channel=2;
switchTimeFeb8=252;
endTimeFeb8=switchTimeFeb8+6.5*12;
temp=cExperimentFeb8.cellInf(1).mean;
temp=temp(:,1:size(temp,2));

cellsPresentFeb8=min(temp')>0;

temp=cExperimentFeb8.cellInf(2).median;
temp=temp(:,30:endTimeFeb8);
cellsPresent2=max(temp')>1e3;
cellsPresentFeb8=cellsPresentFeb8&cellsPresent2;

cellInfFeb8=cExperimentFeb8.cellInf(channel);
cellInfFeb8.mean=cellInfFeb8.mean(cellsPresentFeb8,:);
cellInfFeb8.median=cellInfFeb8.median(cellsPresentFeb8,:);
cellInfFeb8.std=cellInfFeb8.std(cellsPresentFeb8,:);
cellInfFeb8.max5=cellInfFeb8.max5(cellsPresentFeb8,:);
cellInfFeb8.radius=cellInfFeb8.radius(cellsPresentFeb8,:);

%%
figure(10);
plot(median(cellInfFeb8.median)')
%%
figure(10);
tempData=cellInfFeb8.median(:,switchTimeFeb8:endTimeFeb8);
tempPlot=median(tempData)';
error=std(tempData)';
error=error/sqrt(size(tempData,1));
x=5:5:size(tempData,2)*5;
x=x/60;
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Median GAL10::GFP induction after 21 hours');
xlabel('time (hours)');ylabel('Median Cell Fluorescence (AU)');

%%
temp=cellInfFeb8.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%
temp=cExperimentFeb8.cellInf(1).max5(cellsPresentFeb8,100:end);
figure(11);imshow(temp,[]);colormap(jet);

%%
temp=cExperimentFeb8.cellInf(1).mean(cellsPresentFeb8,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentFeb8.cellInf(channel).mean,2);
for cell=1:size(cExperimentFeb8.cellInf(channel).mean,1)
    meancell=cExperimentFeb8.cellInf(channel).mean(cell,:);
    max5cell=cExperimentFeb8.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 60e3]);
    pause(2);
end
