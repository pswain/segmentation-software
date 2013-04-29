uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentAug26=cExperiment;
clear cExperiment;
%%

%% GFP
figure(2);
plot((mean(cExperimentAug26.cellInf(2).max5)-backgroundAug26)'./(mean(cExperimentAug26.cellInf(2).smallmedian)-backgroundAug26)');
figure(3);
plot((mean(cExperimentAug26.cellInf(2).smallmax5/5)-backgroundAug26)'./(mean(cExperimentAug26.cellInf(2).smallmedian)-backgroundAug26)');

%%
backgroundAug26=[];
for i=1:size(cExperimentAug26.cellInf(2).imBackground,2)
    backgroundAug26(:,i)=mean(cExperimentAug26.cellInf(2).imBackground(cExperimentAug26.cellInf(2).imBackground(:,i)>0,i));
    if find(cExperimentAug26.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end

% backgroundAug26=median(cExperimentAug26.cellInf(2).imBackground);
figure(4);
plot(backgroundAug26);title('Median non-cell Fluorescence for all traps');
xlabel('timepoint');
ylabel('Fluorescence (AU)')
% backgroundAug26=median(backgroundAug26(backgroundAug26>0));
%%
figure(4);
plot(median(cExperimentAug26.cellInf(2).std)');

%% GFP
figure(4);
plot(median(cExperiment.cellInf(2).max5./cExperiment.cellInf(2).median)');

%% cy5
cy5=[];
for i=1:size(cExperimentAug26.cellInf(3).median,2)
    cy5(i,:)=median(cExperimentAug26.cellInf(3).median(cExperimentAug26.cellInf(3).median(:,i)>0,i));
end
figure(123);plot(cy5');title('Cy5 median intensity in segmented cell');
xlabel('timepoint');
ylabel('Fluorescence (AU)')

shg
%% make sure cells are present after stimulus
channel=2;
switchTimeAug26=29-4;
endTimeAug26=412+30;
temp=cExperimentAug26.cellInf(1).mean;
temp=temp(:,switchTimeAug26:endTimeAug26);

cellsPresentAug26=min(temp')>0;

% temp=cExperimentAug26.cellInf(2).median;
% temp=temp(:,30:endTimeAug26);
% cellsPresent2=max(temp')>10;
% cellsPresentAug26=cellsPresentAug26&cellsPresent2;

cellInfAug26=cExperimentAug26.cellInf(channel);
cellInfAug26.mean=cellInfAug26.mean(cellsPresentAug26,:);
cellInfAug26.median=cellInfAug26.median(cellsPresentAug26,:);
cellInfAug26.std=cellInfAug26.std(cellsPresentAug26,:);
cellInfAug26.max5=cellInfAug26.max5(cellsPresentAug26,:);
cellInfAug26.radius=cellInfAug26.radius(cellsPresentAug26,:);
cellInfAug26.smallmax5=double(cellInfAug26.smallmax5(cellsPresentAug26,:));
cellInfAug26.smallmedian=double(cellInfAug26.smallmedian(cellsPresentAug26,:));

%%
figure(10);
bkg=repmat(backgroundAug26',[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5)./(cellInfAug26.smallmedian);
ratio1=median(tempData2Plot(:,switchTimeAug26:endTimeAug26));
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundAug26(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
ratio2=median(tempData2Plot);
plot(ratio2);title('msn2 nuclear loc corrected with GFP backgroundAug26')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(12);
plot([ratio1;ratio2]');title('msn2 nuclear loc corrected with GFP backgroundAug26')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('Uncorrected','Corrected')
%%

figure(10);
tempData2Plot=(cellInfAug26.max5)./(cellInfAug26.smallmedian);
ratio1=median(tempData2Plot(:,switchTimeAug26:endTimeAug26));
tempData2Plot=(cellInfAug26.smallmax5/5)./(cellInfAug26.smallmedian);
ratio2=median(tempData2Plot(:,switchTimeAug26:endTimeAug26));

plot([ratio1;ratio2]');title('median msn2 nuc loc - alternative nuclear detection')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('max5 Max:Med=1.41','+ cross correlation Max:Med=1.39')

max(ratio1)/median(ratio1)
max(ratio2)/median(ratio2)
%%
tback=smooth(backgroundAug26,2)';
bkg=repmat(tback(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);

figure(123);imshow(tempData2Plot,[]);colormap(jet)


%%
b=(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
figure(123);imshow(b>0,[]);colormap(jet)



%% Extracting the fractions that fire at each switch
tback=smooth(backgroundAug26,2)';
switchTimeAug26=1;

bkg=repmat(tback(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);

bob=tempData2Plot;
medianFl=median(bob(~isnan(bob(:))));
temp=bob(~isnan(bob(:)) & ~isinf(bob(:)));
stdFl=std(temp-medianFl);

spikeCutoff=2-medianFl;

filteredTraces=bob-medianFl;
spikes=filteredTraces>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);

spike_fraction=[];
spikeTiming=[30 221 412];
spike_fraction(1)=sum(spikes(:,spikeTiming(1)));

spike_fraction(2)=sum(spikes(:,spikeTiming(2)));

spike_fraction(3)=sum(spikes(:,spikeTiming(3)))

loc=filteredTraces(:,spikeTiming(1))>spikeCutoff;
spikeStrength=mean(filteredTraces(loc,spikeTiming(1)));

averageTrace=mean(filteredTraces);

for i=2:3
predictedSpikeStrength=spike_fraction(i)/spike_fraction(1)*spikeStrength;
spikeDifference=(averageTrace(spikeTiming(i))-predictedSpikeStrength)/predictedSpikeStrength*100
end

%%

spikeAllTimes=filteredTraces(:,spikeTiming(1:3))>spikeCutoff;
spikeAllTimes=sum(spikeAllTimes,2)>2;
spikeAllTimesAv=median(filteredTraces(spikeAllTimes,:));
figure(111);plot(timepoints,spikeAllTimesAv+medianFl);xlabel('Hours');pause(1);title('Only cells responding to all 3 limitations (n=87)');axis([0 max(timepoints) 1 4]);
spikeFirst=filteredTraces(:,spikeTiming(1))>spikeCutoff;
figure(112);plot(timepoints,median(filteredTraces(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 1 4]);


