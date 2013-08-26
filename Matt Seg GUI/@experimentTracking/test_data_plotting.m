%% Extracts data and plots averages of cell responses

timeStep=2.5;
timepoints=0:timeStep/60:(length(cExperiment.cellInf(1).extractedMedian)-1)*timeStep/60;

fl1=[];fl2=[];fl3=[];
for cell=1:length(cExperiment.cellInf)
    fl1(cell,:)=cExperiment.cellInf(cell).extractedMax5;
    fl2(cell,:)=cExperiment.cellInf(cell).extractedMean;
    fl3(cell,:)=cExperiment.cellInf(cell).extractedMedian;
end

fl1(fl1==0)=1e-6;
fl2(fl2==0)=1e-6;
fl3(fl3==0)=1e-6;

fl1new=[];fl2new=[];fl3new=[];
numcells=[];
for i=1:length(cExperiment.cellInf(1).extractedMean)
    fl1new(i)=mean(fl1(fl1(:,i)>0,i));
    fl2new(i)=mean(fl2(fl2(:,i)>0,i));
    fl3new(i)=mean(fl3(fl3(:,i)>0,i));
    numcells(i)=sum(fl1(:,i)>0);
end
fl1new=smooth(fl1new,2,'moving');
fl2new=smooth(fl2new,2,'moving');
fl3new=smooth(fl3new,2,'moving');

figure(101);plot(timepoints,fl1new);xlabel('Hours');axis([0 max(timepoints) 500 1.5e3]);
% figure(102);plot(fl2new)
% figure(103);plot(fl3new)

figure(111);plot(timepoints,fl1new./fl3new);xlabel('Hours');axis([0 max(timepoints) 1 4]);
%% Shows number of cells present at each timepoint
numcells=sum(fl1>0);
figure(99);plot(numcells);axis([0 length(fl1) 0 max(numcells)]);
%%

figure(111);plot(timepoints,fl1new./fl3new);xlabel('Hours')
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

bob(i,:)=fl1temp./fl3temp;
end
figure(10);imshow(bob,[]);colormap(jet);impixelinfo()
%%
medianFl=median(bob(~isnan(bob(:))));
spikeCutoff=2-medianFl;

filteredTraces=bob-medianFl;
spikes=filteredTraces>spikeCutoff;
figure(10);imshow(spikes,[]);colormap(jet);impixelinfo()

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
figure(111);plot(timepoints,spikeAllTimesAv);xlabel('Hours');pause(1);
spikeFirst=filteredTraces(:,spikeTiming(1))>spikeCutoff;
figure(112);plot(timepoints,median(filteredTraces(spikeFirst,:)));xlabel('Hours')

%%
figure(101);plot(timepoints,bob(1:5,:)');xlabel('Hours');
%% The switch back to high glucose, and the bursting there
tp1=25*2.5/timeStep;
peakwidth=14*2.5/timeStep;
lowgluc=2*60/timeStep;
highgluc=6*60/timeStep;

% lowgluc1=tp1+lowgluc:tp1+lowgluc+highgluc;
% lowgluc2=tp1+lowgluc+highgluc:tp1+lowgluc*2+highgluc;
% lowgluc3=tp1+lowgluc*2+highgluc:tp1+lowgluc*2+highgluc*2;
tp_start=tp1+lowgluc;
highgluc1=tp_start:tp_start+highgluc;
tp_start=tp_start+highgluc+lowgluc;
highgluc2=tp_start:tp_start+highgluc;
tp_start=tp_start+highgluc+lowgluc;
highgluc3=tp_start:tp_start+highgluc;
highgluc3=highgluc3(highgluc3<length(bob));

highgluc1=round(highgluc1);
highgluc2=round(highgluc2);
highgluc3=round(highgluc3);

st1=std(bob(:,highgluc1)')./mean(bob(:,highgluc1)');
mean(st1(~isnan(st1)))

st2=std(bob(:,highgluc2)')./mean(bob(:,highgluc2)');
mean(st2(~isnan(st2)))

st3=std(bob(:,highgluc3)')./mean(bob(:,highgluc3)');
mean(st3(~isnan(st3)))

%% The bursting after the switch, and after the initial peak
peakwidth=20/2.5*timeStep;
tp_start=tp1+peakwidth;
lowgluc1=tp_start:tp_start+lowgluc-peakwidth;
tp_start=tp_start+highgluc+lowgluc;
lowgluc2=tp_start:tp_start+lowgluc-peakwidth;
tp_start=tp_start+highgluc+lowgluc;
lowgluc3=tp_start:tp_start+lowgluc-peakwidth;

st1=std(bob(:,lowgluc1)')./mean(bob(:,lowgluc1)');
median(st1(~isnan(st1)))

st2=std(bob(:,lowgluc2)')./mean(bob(:,lowgluc2)');
mean(st2(~isnan(st2)))

st3=std(bob(:,lowgluc3)')./mean(bob(:,lowgluc3)');
mean(st3(~isnan(st3)))

%% Looks at the max peak post switch for each of the 3 stimulus
peakwidth=20*2.5/timeStep;
tp_start=tp1;
lowgluc1=tp_start:tp_start+peakwidth;
tp_start=tp_start+highgluc+lowgluc;
lowgluc2=tp_start:tp_start+peakwidth;
tp_start=tp_start+highgluc+lowgluc;
lowgluc3=tp_start:tp_start+peakwidth;

st1=max(bob(:,lowgluc1)');
median(st1(~isnan(st1)))-median(bob(~isnan(bob)))

st2=max(bob(:,lowgluc2)');
median(st2(~isnan(st2)))-median(bob(~isnan(bob)))

st3=max(bob(:,lowgluc3)');
median(st3(~isnan(st3)))-median(bob(~isnan(bob)))
%%
lowgluc1(1)*timeStep
lowgluc1(end)*timeStep
lowgluc2(1)*timeStep
lowgluc2(end)*timeStep
lowgluc3(1)*timeStep
lowgluc3(end)*timeStep
%%
bobby=unique(bob(:,1));
%%
fft(bob(1,tp1))