
uiload
%% Extracts data and plots averages of cell responses

timeStep=2.5;
% timeStep=2;
timepoints=0:timeStep/60:(length(cExperiment.cellInf(1).extractedMedian)-1)*timeStep/60;

fl1=[];fl2=[];fl3=[];
for cell=1:length(cExperiment.cellInf)
    fl1(cell,:)=cExperiment.cellInf(cell).extractedMax5;
    fl2(cell,:)=cExperiment.cellInf(cell).extractedMean;
    fl3(cell,:)=cExperiment.cellInf(cell).extractedMedian;
end

% fl1(fl1==0)=1e-6;
% fl2(fl2==0)=1e-6;
% fl3(fl3==0)=1e-6;

fl1new=[];fl2new=[];fl3new=[];
numcells=[];
error=[];
for i=1:length(cExperiment.cellInf(1).extractedMean)
    fl1new(i)=mean(fl1(fl1(:,i)>0,i));
    fl2new(i)=mean(fl2(fl2(:,i)>0,i));
    fl3new(i)=mean(fl3(fl3(:,i)>0,i));
    error(i)=std(fl1(fl1(:,i)>0,i)./fl3(fl3(:,i)>0,i));
    numcells(i)=sum(fl1(:,i)>0);
end
fl1new=smooth(fl1new,2,'moving');
fl2new=smooth(fl2new,2,'moving');
fl3new=smooth(fl3new,2,'moving');

figure(101);plot(timepoints,fl1new);xlabel('Hours');axis([0 max(timepoints) 500 1.5e3]);
% figure(102);plot(fl2new)
% figure(103);plot(fl3new)
plotData=fl1new./fl3new;
numcells=sum(fl1>0);

error=error/sqrt(mean(numcells));
figure(111);plot(timepoints,plotData);xlabel('Hours');axis([0 max(timepoints) 1 4]);ylabel('Nuclear localization (AU)');
figure(111);errorbar(timepoints,plotData,error);xlabel('Hours');axis([0 max(timepoints) 1 4]);ylabel('Nuclear localization (AU)');
title('msn2::gfp after pulses of gluocse limitation (n~140)');
% figure(111);errorbar(timepoints,plotData,error./sqrt(numcells));xlabel('Hours');axis([0 max(timepoints) 1 4]);

%% Shows number of cells present at each timepoint
numcells=sum(fl1>0);
figure(99);plot(numcells);axis([0 length(fl1) 0 max(numcells)]);
%% Shows movie of single cell traces

f1=figure(10);ax1=gca;

for cell=1:length(cExperiment.cellInf)
    meancell=cExperiment.cellInf(cell).extractedMedian;
    max5cell=cExperiment.cellInf(cell).extractedMax5;
    plot(ax1,timepoints,max5cell./meancell);xlabel('Hours');
    axis([0 max(timepoints) 1 5]);
    pause(2);
end
%% Shows collection of single cell traces
bob=[];

for i=1:length(cExperiment.cellInf)
fl1temp=fl1(i,:);
fl2temp=fl2(i,:);
fl3temp=fl3(i,:);

fl1temp=smooth(fl1temp,2);
fl2temp=smooth(fl2temp,2);
fl3temp=smooth(fl3temp,2);

fl3temp(fl3temp==0)=1e-9;
bob(i,:)=fl1temp./fl3temp;
end
figure(10);imshow(bob,[1 7]);colormap(jet);

m=median(bob,2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(fl1,1)
    temp2(i,:)=bob(loc(i),:);
end 
figure(10);imshow(temp2,[1 7]);colormap(jet);

%% trying to figure out the decline in the response to glucose limitation and whether that 
% correlates with sensence or wether the 
medianFl=median(bob(~isnan(bob(:))));
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


%% clustering
