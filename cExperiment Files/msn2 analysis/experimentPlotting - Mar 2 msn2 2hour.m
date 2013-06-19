uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentMar2=cExperiment;
clear cExperiment;
%%

%% GFP
figure(2);
plot((mean(cExperimentMar2.cellInf(2).max5)-background)'./(mean(cExperimentMar2.cellInf(2).smallmedian)-background)');
figure(3);
plot(mean(cExperimentMar2.cellInf(2).smallmax5/5-background)'./mean(cExperimentMar2.cellInf(2).smallmedian-background)');

%%
background=median(cExperimentMar2.cellInf(2).imBackground);
% background=median(background(background>0));
%%
figure(3);
plot(median(cExperimentMar2.cellInf(2).std)');

%% GFP
figure(4);
plot(median(cExperiment.cellInf(2).max5./cExperiment.cellInf(2).median)');

%% cy5
plot(mean(cExperimentMar2.cellInf(3).mean)')
fig
%% make sure cells are present after stimulus
channel=2;
switchTimeMar2=29-2*12;
endTimeMar2=switchTimeMar2+4*12;
temp=cExperimentMar2.cellInf(1).mean;
temp=temp(:,switchTimeMar2:endTimeMar2);

cellsPresentMar2=min(temp')>0;

% temp=cExperimentMar2.cellInf(2).median;
% temp=temp(:,30:endTimeMar2);
% cellsPresent2=max(temp')>10;
% cellsPresentMar2=cellsPresentMar2&cellsPresent2;

cellInfMar2=cExperimentMar2.cellInf(channel);
cellInfMar2.mean=cellInfMar2.mean(cellsPresentMar2,:);
cellInfMar2.median=cellInfMar2.median(cellsPresentMar2,:);
cellInfMar2.std=cellInfMar2.std(cellsPresentMar2,:);
cellInfMar2.max5=cellInfMar2.max5(cellsPresentMar2,:);
cellInfMar2.radius=cellInfMar2.radius(cellsPresentMar2,:);
cellInfMar2.smallmax5=double(cellInfMar2.smallmax5(cellsPresentMar2,:));
cellInfMar2.smallmedian=double(cellInfMar2.smallmedian(cellsPresentMar2,:));

%%
figure(10);
bkg=repmat(background,[size(cellInfMar2.max5,1) 1]);
plot(median((cellInfMar2.max5-bkg)./(cellInfMar2.smallmedian-bkg)));
%% Plot cells post stimulus 
figure(10);
tempData=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)./cellInfMar2.median(:,switchTimeMar2:endTimeMar2));
tempPlot=mean(tempData)';
error=std(tempData)';
error=error/sqrt(size(tempData,1));
x=5:5:size(tempData,2)*5;
x=x/60;
x=x-2;
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Mean nuclear localization (n~130)');
xlabel('time (hours)');ylabel('Nuclear localization (AU)');

%%
temp=cellInfMar2.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%
temp=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)./cellInfMar2.median(:,switchTimeMar2:endTimeMar2));
figure(11);imshow(temp,[]);colormap(jet);
%%
%% Pretty Kymograph
temp=cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)./cellInfMar2.median(:,switchTimeMar2:endTimeMar2);
m=median(temp(:,25:28),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=smooth(temp(loc(i),:),1);
end
temp2(1,:)=[];
figure(11);imshow(temp2,[1 5]);colormap(jet);impixelinfo
%%
%%
medianFl=median(temp2(~isnan(temp2(:))));
spikeCutoff=1.2*medianFl;

filteredTraces=temp2;%-medianFl;
spikes=filteredTraces>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);

sum(spikes(:,25))/size(spikes,1)

%% single cell examples
tempD=temp2([1 5 20 40 45],:)';
figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([-2 2 1 5]);
xlabel('time (hours)'); ylabel('Nuclear localization (AU)');title('2 hour old cells experiencing glucose limitation')

%% Pretty Kymograph cells normalized to intensity
temp=cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)./cellInfMar2.median(:,switchTimeMar2:endTimeMar2);
m=median(temp(:,25:28),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
    temp2(i,:)=temp2(i,:)/max(temp2(i,:));

end
figure(11);imshow(temp2,[]);colormap(jet);



%%
temp=cExperimentMar2.cellInf(1).mean(cellsPresentMar2,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentMar2.cellInf(channel).mean,2);
for cell=1:size(cExperimentMar2.cellInf(channel).mean,1)
    meancell=cExperimentMar2.cellInf(channel).mean(cell,:);
    max5cell=cExperimentMar2.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 60e3]);
    pause(2);
end
