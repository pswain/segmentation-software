uiload();
cExperiment.correctSkippedFramesInf
cExperimentFeb11=cExperiment;
clear cExperiment;
%%
plot(mean(cExperimentFeb11.cellInf(2).mean)')
fig
%%
channel=2;
switchTimeFeb11=1;
endTimeFeb11=320;
temp=cExperimentFeb11.cellInf(1).median;
temp=temp(:,1:size(temp,2));

cellsPresentFeb11=min(temp')>-1;

temp=cExperimentFeb11.cellInf(2).median;
temp=temp(:,1:endTimeFeb11);
cellsPresent2=max(temp')>.1e1;
cellsPresentFeb11=cellsPresentFeb11&cellsPresent2;

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
tempData=cellInfFeb11.median(:,switchTimeFeb11:endTimeFeb11);
% tempData=tempData./cellInfFeb11.median(:,switchTimeFeb11:endTimeFeb11);
tempPlot=median(tempData)';
error=std(tempData)';
error=error/sqrt(size(tempData,1));
x=5:5:size(tempData,2)*5;
x=x/60;
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Median HSP104::GFP expression');
xlabel('time (hours)');ylabel('Median Cell Fluorescence (AU)');
axis([0 max(x) min(tempPlot)*.9 max(tempPlot)*1.1])
%%
temp=cellInfFeb11.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
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
