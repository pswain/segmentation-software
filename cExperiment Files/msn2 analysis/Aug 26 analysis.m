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
    backgroundAug26(:,i)=median(cExperimentAug26.cellInf(2).imBackground(cExperimentAug26.cellInf(2).imBackground(:,i)>5,i));
    if find(cExperimentAug26.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end
hold on;
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
endTimeAug26=412+2*12*2;
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
bkg=repmat(backgroundAug26(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
ratio1=median(tempData2Plot);
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundAug26(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.smallmax5(:,switchTimeAug26:endTimeAug26)-bkg)/5./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
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



figure(11);
tempData2Plot=(cellInfAug26.std);
ratio1=median(tempData2Plot(:,switchTimeAug26:endTimeAug26));

plot([ratio1]');title('median msn2 nuc loc - alternative nuclear detection')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
max(ratio1)/median(ratio1)

%%
tback=smooth(backgroundAug26,2)';
bkg=repmat(tback(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);

figure(123);imshow(tempData2Plot,[]);colormap(jet)
impixelinfo

figure(124);imshow(cellInfAug26.smallmax5(:,1:endTimeAug26)/5,[]);colormap(jet)
impixelinfo

figure(125);imshow(cExperimentAug26.cellInf(2).std,[]);colormap(jet);

%%
b=(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
figure(123);imshow(b<0,[]);colormap(jet)
impixelinfo



%% Extracting the fractions that fire at each switch
switchTimeAug26=1;

tback=smooth(backgroundAug26,2)';
bkg=repmat(tback(switchTimeAug26:endTimeAug26),[size(cellInfAug26.max5,1) 1]);
tempData2Plot=(cellInfAug26.max5(:,switchTimeAug26:endTimeAug26)-bkg)./(cellInfAug26.smallmedian(:,switchTimeAug26:endTimeAug26)-bkg);
% tempData2Plot=cellInfAug26.std(:,switchTimeAug26:endTimeAug26);
% bob=tempData2Plot;


bob=tempData2Plot;
x=switchTimeAug26:endTimeAug26;
b=robustfit(x,median(tempData2Plot));
medianFl=b(1)+x*b(2);
figure(234);plot(medianFl)
hold on
plot(median(tempData2Plot))

%%
% medianFl=median(bob);
temp=tempData2Plot(~isnan(bob(:)) & ~isinf(bob(:)));
stdFl=std(temp(:));
% stdFl=mean(temp-mean(medianFl));

spikeCutoff=2*stdFl;

filteredTraces=[]
for i=1:size(bob,1)
filteredTraces(i,:)=smooth((bob(i,:)-medianFl),1);
end
spikes=filteredTraces>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);

spike_fraction=[];
spikeTiming=[29 220 412];
spike_fraction(1)=sum(max(spikes(:,spikeTiming(1):spikeTiming(1)+1),[],2));

spike_fraction(2)=sum(max(spikes(:,spikeTiming(2):spikeTiming(2)+1),[],2));

spike_fraction(3)=sum(max(spikes(:,spikeTiming(3):spikeTiming(3)+1),[],2))


% spike_fraction(1)=sum(spikes(:,spikeTiming(1)));
% spike_fraction(2)=sum(spikes(:,spikeTiming(2)));
% spike_fraction(3)=sum(spikes(:,spikeTiming(3)))

loc=filteredTraces(:,spikeTiming(1))>spikeCutoff;
spikeStrength=mean(filteredTraces(loc,spikeTiming(1)));

averageTrace=mean(filteredTraces);

for i=2:3
predictedSpikeStrength=spike_fraction(i)/spike_fraction(1)*spikeStrength;
spikeDifference=(averageTrace(spikeTiming(i))-predictedSpikeStrength)/predictedSpikeStrength*100
end

%% Plot the fraction of cells that respond each time
timeStep=2.5;
timepoints=0:timeStep/60:(length(switchTimeAug26:endTimeAug26)-1)*timeStep/60;



spikeAllTimes=filteredTraces(:,spikeTiming(1:3))>spikeCutoff;
spikeAllTimes=sum(spikeAllTimes,2)>2;
spikeAllTimesAv=median(filteredTraces(spikeAllTimes,:));
figure(111);plot(timepoints,spikeAllTimesAv);xlabel('Hours');axis([0 max(timepoints) 0 5]);
title(['Only cells responding to all 3 (n=',num2str(sum(spikeAllTimes)),') ',num2str(sum(spikeAllTimes)/length(spikeAllTimes)) ]);
ylabel('Nuclear Localization (AU)');

spikeFirst=filteredTraces(:,spikeTiming(1))>spikeCutoff;
figure(112);plot(timepoints,median(filteredTraces(spikeFirst,:)));xlabel('Hours');axis([0 max(timepoints) 0 5]);
title(['All cells responding to spike 1 (n=',num2str(sum(spikeFirst)),') ',num2str(sum(spikeFirst)/length(spikeFirst)) ]);
ylabel('Nuclear Localization (AU)');

spikeAllTimes=filteredTraces(:,spikeTiming(1:3))>spikeCutoff;
spikeFirstOnly=spikeAllTimes(:,1)& ~max(spikeAllTimes(:,2:3),[],2);
figure(113);plot(timepoints,median(filteredTraces(spikeFirstOnly,:)));xlabel('Hours');axis([0 max(timepoints) 0 5]);
title(['Cells responding to spike 1 only (n=',num2str(sum(spikeFirstOnly)),') ',num2str(sum(spikeFirstOnly)/length(spikeFirstOnly)) ]);
ylabel('Nuclear Localization (AU)');

%% Kymograph

% figure(125);imshow(filteredTraces,[]);colormap(jet);

data=filteredTraces;
data=bob;
data(isnan(data))=median(data(~isnan(data)));
% data(data==0)=min(data(data>0));
% data=zscore(data');
% data=data';
d=pdist(data,'seuclidean');
% d=pdist(data,'cosine');

figure(2);imshow(data,[]);colormap(jet)
%
z=squareform(d);

% figure(10);imshow(z,[])

dataOrdered=[];
[v cellToCluster]=min(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered(i,:)=data(loc,:);
    z(loc,:)=Inf;
end

figure(11);imshow(dataOrdered,[.5 9]);colormap(jet);impixelinfo
%% single cell plots
figure(125);imshow(filteredTraces,[]);colormap(jet);
%%
tempD=filteredTraces([1 13 36 65 80],:)';
x=timepoints;

figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([0 max(x) -.5 6]);
xlabel('time (hours)'); ylabel('Nuclear localization (AU)');title('5 cells experiencing repeated glucose limitation')

%% All cells plot 

dataAll=median(filteredTraces);
errorAll=std(filteredTraces)/sqrt(size(filteredTraces,1));
x=timepoints;
x=[x'];
tempPlot=[dataAll]';

figure(10);
errorbar(x,tempPlot,errorAll);title('Median nuclear localization');
xlabel('time (hours)');ylabel('Nuclear localization (AU)');
legend(['All cells (n=',num2str(size(filteredTraces,1)),')']);
axis([0 max(timepoints) -.5 4]);

%% Plot 1 pulse only vs cells that do all 3 times


spikeAllTimes=filteredTraces(:,spikeTiming(1:3))>spikeCutoff;
spikeAll=sum(spikeAllTimes,2)>2;
dataAll=median(filteredTraces(spikeAll,:));
errorAll=std(filteredTraces(spikeAll,:))/sqrt(sum(spikeAll));

spikeFirstOnly=spikeAllTimes(:,1)& ~max(spikeAllTimes(:,2:3),[],2);
data1=median(filteredTraces(spikeFirstOnly,:));
error1=std(filteredTraces(spikeFirstOnly,:))/sqrt(sum(spikeFirstOnly));

error=[errorAll;error1]';
x=timepoints;
x=[x' x'];
tempPlot=[dataAll;data1]';

figure(10);
errorbar(x,tempPlot,error);title('Median nuclear localization');
xlabel('time (hours)');ylabel('Nuclear localization (AU)');
legend(['Respond to All (n=',num2str(sum(spikeAll)),')'],['Only first(n=',num2str(sum(spikeFirstOnly)),')']);
axis([0 max(timepoints) -.5 4]);
%%
% clc
spikeAllTimes=[];
spikeAllTimes(:,1)=(max(spikes(:,spikeTiming(1):spikeTiming(1)+1),[],2));

spikeAllTimes(:,2)=(max(spikes(:,spikeTiming(2):spikeTiming(2)+1),[],2));

spikeAllTimes(:,3)=(max(spikes(:,spikeTiming(3):spikeTiming(3)+1),[],2));



% spikeAllTimes=filteredTraces(:,spikeTiming(1:3))>spikeCutoff;
spikeFirstOnly=spikeAllTimes(:,1)& ~max(spikeAllTimes(:,2:3),[],2);
disp(['Percent Spiking 1 only ' num2str(100*sum(spikeFirstOnly)/length(spikeFirstOnly))])

col=[1 3];
spike2Only=spikeAllTimes(:,2)& ~max(spikeAllTimes(:,col),[],2);
disp(['Percent Spiking 2 only ' num2str(100*sum(spike2Only)/length(spike2Only))])

spike3Only=spikeAllTimes(:,3)& ~max(spikeAllTimes(:,1:2),[],2);
disp(['Percent Spiking 3 only ' num2str(100*sum(spike3Only)/length(spike3Only))])


spike1and2=sum(spikeAllTimes(:,1:2),2)>1 & ~max(spikeAllTimes(:,3),[],2);
disp(['Percent Spiking 1&2 only ' num2str(100*sum(spike1and2)/length(spike1and2))])

spike2and3=sum(spikeAllTimes(:,2:3),2)>1 & ~max(spikeAllTimes(:,1),[],2);
disp(['Percent Spiking 2&3 only ' num2str(100*sum(spike2and3)/length(spike2and3))])

col=[1 3];
spike1and3=sum(spikeAllTimes(:,col),2)>1 & ~max(spikeAllTimes(:,2),[],2);
disp(['Percent Spiking 1&3 only ' num2str(100*sum(spike1and3)/length(spike1and3))])


spikeAll=sum(spikeAllTimes,2)>2;
disp(['Percent Spiking All ' num2str(100*sum(spikeAll)/length(spikeAll))])



spikeNone=sum(spikeAllTimes,2)==0;
disp(['Percent Spiking None ' num2str(100*sum(spikeNone)/length(spikeNone))])

% disp(['Total' num2str(sum(spikeAll+spike1and3+spike2and3+spike1and2+spike3Only+spike2Only+spikeFirstOnly))/(7*length(spikeFirstOnly))])
