uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentMar2=cExperiment;
clear cExperiment;
%%

%% GFP
%% GFP
figure(2);
plot((mean(cExperimentMar2.cellInf(2).max5)-backgroundMar2)'./(mean(cExperimentMar2.cellInf(2).smallmedian)-backgroundMar2)');
figure(3);
plot((mean(cExperimentMar2.cellInf(2).smallmax5/5)-backgroundMar2)'./(mean(cExperimentMar2.cellInf(2).smallmedian)-backgroundMar2)');

%%
backgroundMar2=[];
for i=1:size(cExperimentMar2.cellInf(2).imBackground,2)
    backgroundMar2(:,i)=median(cExperimentMar2.cellInf(2).imBackground(cExperimentMar2.cellInf(2).imBackground(:,i)>0,i));
end

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
bkg=repmat(backgroundMar2',[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5)./(cellInfMar2.smallmedian);
ratio1=median(tempData2Plot(:,switchTimeMar2:endTimeMar2));
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundMar2(switchTimeMar2:endTimeMar2),[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg)./(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);
ratio2=median(tempData2Plot);
plot(ratio2);title('msn2 nuclear loc corrected with GFP backgroundMar2')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(12);
plot([ratio1;ratio2]');title('msn2 nuclear loc corrected with GFP backgroundMar2')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('Uncorrected','Corrected')
%%

figure(10);
tempData2Plot=(cellInfMar2.max5)./(cellInfMar2.smallmedian);
ratio1=median(tempData2Plot(:,switchTimeMar2:endTimeMar2));
tempData2Plot=(cellInfMar2.smallmax5/5)./(cellInfMar2.smallmedian);
ratio2=median(tempData2Plot(:,switchTimeMar2:endTimeMar2));

plot([ratio1;ratio2]');title('median msn2 nuc loc - alternative nuclear detection')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('max5 Max:Med=1.41','+ cross correlation Max:Med=1.39')

max(ratio1)/median(ratio1)
max(ratio2)/median(ratio2)
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

%%
tback=smooth(backgroundMar2,2);
bkg=repmat(tback',[size(cellInfMar2.max5,1) 1]);
tempData2Plot=(cellInfMar2.max5)./(cellInfMar2.smallmedian);

figure(123);imshow(tempData2Plot,[]);colormap(jet)
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
