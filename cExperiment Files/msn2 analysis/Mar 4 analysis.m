uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentMar4=cExperiment;
clear cExperiment;
%%

%% GFP
figure(2);
plot((mean(cExperimentMar4.cellInf(2).max5)-backgroundMar4)'./(mean(cExperimentMar4.cellInf(2).smallmedian)-backgroundMar4)');
figure(3);
plot((mean(cExperimentMar4.cellInf(2).smallmax5/5)-backgroundMar4)'./(mean(cExperimentMar4.cellInf(2).smallmedian)-backgroundMar4)');

%%
backgroundMar4=[];
for i=1:size(cExperimentMar4.cellInf(2).imBackground,2)
    backgroundMar4(:,i)=median(cExperimentMar4.cellInf(2).imBackground(cExperimentMar4.cellInf(2).imBackground(:,i)>5,i));
    if find(cExperimentMar4.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end
hold on;
% backgroundMar4=median(cExperimentMar4.cellInf(2).imBackground);
figure(4);
plot(backgroundMar4);title('Median non-cell Fluorescence for all traps');
xlabel('timepoint');
ylabel('Fluorescence (AU)')
% backgroundMar4=median(backgroundMar4(backgroundMar4>0));
%%
figure(4);
plot(median(cExperimentMar4.cellInf(2).std)');

%% GFP
figure(4);
plot(median(cExperiment.cellInf(2).max5./cExperiment.cellInf(2).median)');

%% cy5
cy5=[];
for i=1:size(cExperimentMar4.cellInf(3).median,2)
    cy5(i,:)=median(cExperimentMar4.cellInf(3).median(cExperimentMar4.cellInf(3).median(:,i)>0,i));
end
figure(123);plot(cy5');title('Cy5 median intensity in segmented cell');
xlabel('timepoint');
ylabel('Fluorescence (AU)')

shg
%% make sure cells are present after stimulus
channel=2;
switchTimeMar4=219-.5*12;
endTimeMar4=switchTimeMar4+1.5*12;
temp=cExperimentMar4.cellInf(1).mean;
temp=temp(:,switchTimeMar4:endTimeMar4);

cellsPresentMar4=min(temp')>0;

% temp=cExperimentMar4.cellInf(2).median;
% temp=temp(:,30:endTimeMar4);
% cellsPresent2=max(temp')>10;
% cellsPresentMar4=cellsPresentMar4&cellsPresent2;

cellInfMar4=cExperimentMar4.cellInf(channel);
cellInfMar4.mean=cellInfMar4.mean(cellsPresentMar4,:);
cellInfMar4.median=cellInfMar4.median(cellsPresentMar4,:);
cellInfMar4.std=cellInfMar4.std(cellsPresentMar4,:);
cellInfMar4.max5=cellInfMar4.max5(cellsPresentMar4,:);
cellInfMar4.radius=cellInfMar4.radius(cellsPresentMar4,:);
cellInfMar4.smallmax5=double(cellInfMar4.smallmax5(cellsPresentMar4,:));
cellInfMar4.smallmedian=double(cellInfMar4.smallmedian(cellsPresentMar4,:));

%%
figure(10);
bkg=repmat(backgroundMar4(switchTimeMar4:endTimeMar4),[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)-bkg)./(cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg);
ratio1=median(tempData2Plot);
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundMar4(switchTimeMar4:endTimeMar4),[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.smallmax5(:,switchTimeMar4:endTimeMar4)-bkg)/5./(cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg);
ratio2=median(tempData2Plot);
plot(ratio2);title('msn2 nuclear loc corrected with GFP backgroundMar4')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(12);
plot([ratio1;ratio2]');title('msn2 nuclear loc corrected with GFP backgroundMar4')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('Uncorrected','Corrected')

%%
tback=smooth(backgroundMar4,2)';
bkg=repmat(tback(switchTimeMar4:endTimeMar4),[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)-bkg)./(cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg);

figure(123);imshow(tempData2Plot,[]);colormap(jet)
impixelinfo

figure(124);imshow(cellInfMar4.smallmax5(:,1:endTimeMar4)/5,[]);colormap(jet)
impixelinfo

figure(125);imshow(cExperimentMar4.cellInf(2).std,[]);colormap(jet);


%% Extracting the fractions that fire at each switch
switchTimeMar4=1;

tback=smooth(backgroundMar4,2)';
bkg=repmat(tback(switchTimeMar4:endTimeMar4),[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)-bkg)./(cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg);

bob=tempData2Plot;
x=switchTimeMar4:endTimeMar4;
b=robustfit(x,median(tempData2Plot));
medianFlMar4=b(1)+x*b(2);
figure(234);plot(medianFlMar4)
hold on
plot(median(tempData2Plot))
bobMar4=tempData2Plot;
%%
% medianFlMar4=median(bob);
temp=bobMar4(~isnan(bobMar4(:)) & ~isinf(bobMar4(:)));
stdFl=std(temp(:));
% stdFl=mean(temp-mean(medianFlMar4));

spikeCutoff=.4*stdFl;
%%
filteredTracesMar4=[];
for i=1:size(bob,1)
filteredTracesMar4(i,:)=(bobMar4(i,:)-medianFlMar4);
end
% filteredTraces=bob-medianFlMar4;
spikes=filteredTracesMar4>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);

spike_fraction=[];
k=218;
spikeTiming=[k:k+1];
spike_fraction(1)=sum(max(spikes(:,spikeTiming),[],2))


loc=filteredTracesMar4(:,spikeTiming(1))>spikeCutoff;

averageTrace=mean(filteredTraces);

spike_fraction/size(filteredTracesMar4,1)
%% Plot the fraction of cells that respond each time
timeStep=5;
timepoints=0:timeStep/60:(length(switchTimeMar4:endTimeMar4)-1)*timeStep/60;




spikeFirst=filteredTracesMar4(:,spikeTiming(1))>spikeCutoff;
figure(112);plot(timepoints,median(filteredTracesMar4(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 0 3]);
title(['All cells responding to spike 1 (n=',num2str(sum(spikeFirst)),') ',num2str(sum(spikeFirst)/length(spikeFirst)) ]);

spikeFirst=filteredTracesMar4(:,spikeTiming(1))<spikeCutoff;
figure(113);plot(timepoints,median(filteredTracesMar4(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 0 3]);
title(['All cells NOT responding to spike 1 (n=',num2str(sum(spikeFirst)),') ',num2str(sum(spikeFirst)/length(spikeFirst)) ]);


%%
clc
spikeHeight=filteredTracesMar4(:,spikeTiming(1:3));
sum((spikeHeight(:,3)>spikeHeight(:,1)))

sum((spikeHeight(:,3)<spikeHeight(:,1)))

sum((spikeHeight(:,2)>spikeHeight(:,1)) & (spikeHeight(:,3)>spikeHeight(:,1)))

