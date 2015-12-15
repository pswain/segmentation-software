uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentMar2=cExperiment;
clear cExperiment;
%%

%% GFP
figure(2);
plot((mean(cExperimentMar2.cellInf(2).max5)-backgroundMar2)'./(mean(cExperimentMar2.cellInf(2).smallmedian)-backgroundMar2)');
figure(3);
plot((mean(cExperimentMar2.cellInf(2).smallmax5/5)-backgroundMar2)'./(mean(cExperimentMar2.cellInf(2).smallmedian)-backgroundMar2)');

%%
backgroundMar2=[];
for i=1:size(cExperimentMar2.cellInf(2).imBackground,2)
    backgroundMar2(:,i)=median(cExperimentMar2.cellInf(2).imBackground(cExperimentMar2.cellInf(2).imBackground(:,i)>5,i));
    if find(cExperimentMar2.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end
hold on;
% backgroundMar2=median(cExperimentMar2.cellInf(2).imBackground);
figure(4);
plot(backgroundMar2);title('Median non-cell Fluorescence for all traps');
xlabel('timepoint');
ylabel('Fluorescence (AU)')
% backgroundMar2=median(backgroundMar2(backgroundMar2>0));
%%
figure(4);
plot(median(cExperimentMar2.cellInf(2).std)');

%% GFP
figure(4);
plot(median(cExperiment.cellInf(2).max5./cExperiment.cellInf(2).median)');

%% cy5
cy5=[];
for i=1:size(cExperimentMar2.cellInf(3).median,2)
    cy5(i,:)=median(cExperimentMar2.cellInf(3).median(cExperimentMar2.cellInf(3).median(:,i)>0,i));
end
figure(123);plot(cy5');title('Cy5 median intensity in segmented cell');
xlabel('timepoint');
ylabel('Fluorescence (AU)')

shg
%% make sure cells are present after stimulus
channel=2;
switchTimeMar2=29-.5*12;
endTimeMar2=switchTimeMar2+3*12;
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
bkg=repmat(backgroundMar2(switchTimeMar2:endTimeMar2),[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg)./(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);
ratio1=median(tempData2Plot);
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundMar2(switchTimeMar2:endTimeMar2),[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.smallmax5(:,switchTimeMar2:endTimeMar2)-bkg)/5./(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);
ratio2=median(tempData2Plot);
plot(ratio2);title('msn2 nuclear loc corrected with GFP backgroundMar2')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(12);
plot([ratio1;ratio2]');title('msn2 nuclear loc corrected with GFP backgroundMar2')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('Uncorrected','Corrected')

%%
tback=smooth(backgroundMar2,2)';
bkg=repmat(tback(switchTimeMar2:endTimeMar2),[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg)./(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);

figure(123);imshow(tempData2Plot,[]);colormap(jet)
impixelinfo

figure(124);imshow(cellInfMar2.smallmax5(:,1:endTimeMar2)/5,[]);colormap(jet)
impixelinfo

figure(125);imshow(cExperimentMar2.cellInf(2).std,[]);colormap(jet);


%% Extracting the fractions that fire at each switch
switchTimeMar2=1;

tback=smooth(backgroundMar2,2)';
bkg=repmat(tback(switchTimeMar2:endTimeMar2),[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg)./(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);

bob=tempData2Plot;
x=switchTimeMar2:endTimeMar2;
b=robustfit(x,median(tempData2Plot));
medianFlMar2=b(1)+x*b(2);
figure(234);plot(medianFlMar2)
hold on
plot(median(tempData2Plot))
bobMar2=tempData2Plot;
%%
% medianFlMar2=median(bob);
temp=bobMar2(~isnan(bobMar2(:)) & ~isinf(bobMar2(:)));
stdFl=std(temp(:));
% stdFl=mean(temp-mean(medianFlMar2));

spikeCutoff=.4*stdFl;
%%
filteredTracesMar2=[];
for i=1:size(bob,1)
filteredTracesMar2(i,:)=(bobMar2(i,:)-medianFlMar2);
end
% filteredTraces=bob-medianFlMar2;
spikes=filteredTracesMar2>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);

spike_fraction=[];
k=29;
spikeTiming=[k:k+1];
spike_fraction(1)=sum(max(spikes(:,spikeTiming),[],2))


loc=filteredTracesMar2(:,spikeTiming(1))>spikeCutoff;
spikeStrength=mean(filteredTracesMar2(loc,spikeTiming(1)));

averageTrace=mean(filteredTracesMar2);

spike_fraction/size(filteredTracesMar2,1)
%% Plot the fraction of cells that respond each time
timeStep=5;
timepoints=0:timeStep/60:(length(switchTimeMar2:endTimeMar2)-1)*timeStep/60;




spikeFirst=filteredTracesMar2(:,spikeTiming(1))>spikeCutoff;
figure(112);plot(timepoints,median(filteredTracesMar2(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 0 3]);
title(['All cells responding to spike 1 (n=',num2str(sum(spikeFirst)),') ',num2str(sum(spikeFirst)/length(spikeFirst)) ]);

spikeFirst=filteredTracesMar2(:,spikeTiming(1))<spikeCutoff;
figure(113);plot(timepoints,median(filteredTracesMar2(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 0 3]);
title(['All cells NOT responding to spike 1 (n=',num2str(sum(spikeFirst)),') ',num2str(sum(spikeFirst)/length(spikeFirst)) ]);


%%
clc
spikeHeight=filteredTracesMar2(:,spikeTiming(1:3));
sum((spikeHeight(:,3)>spikeHeight(:,1)))

sum((spikeHeight(:,3)<spikeHeight(:,1)))

sum((spikeHeight(:,2)>spikeHeight(:,1)) & (spikeHeight(:,3)>spikeHeight(:,1)))

