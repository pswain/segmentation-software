uiload();
%%
cExperiment.correctSkippedFramesInf
cExperimentMar4=cExperiment;
clear cExperiment;
%% GFP
plot(mean(cExperimentMar4.cellInf(2).max5)'./mean(cExperimentMar4.cellInf(2).median)');
fig
%% cy5
plot(mean(cExperimentMar4.cellInf(3).mean)')
fig
%%
%%
backgroundMar4=[];
for i=1:size(cExperimentMar4.cellInf(2).imBackground,2)
    backgroundMar4(:,i)=median(cExperimentMar4.cellInf(2).imBackground(cExperimentMar4.cellInf(2).imBackground(:,i)>0,i));
end

% backgroundMar4=median(cExperimentMar4.cellInf(2).imBackground);
figure(4);
plot(backgroundMar4);title('Median non-cell Fluorescence for all traps');
xlabel('timepoint');
ylabel('Fluorescence (AU)')
% backgroundMar4=median(backgroundMar4(backgroundMar4>0));
%% make sure cells are present after stimulus
channel=2;
switchTimeMar4=219-2*12;
endTimeMar4=switchTimeMar4+4*12;
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
%%
figure(10);
bkg=repmat(backgroundMar4',[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.max5)./(cellInfMar4.smallmedian);
ratio1=median(tempData2Plot(:,switchTimeMar4:endTimeMar4));
plot(ratio1);title('msn2 nuclear loc uncorrected')
xlabel('timepoints');ylabel('Nuclear localization (AU)');

figure(11);
bkg=repmat(backgroundMar4(switchTimeMar4:endTimeMar4),[size(cellInfMar4.max5,1) 1]);
tempData2Plot=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)-bkg)./(cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg);
ratio2=median(tempData2Plot);
plot(ratio2);title('msn2 nuclear loc corrected with GFP backgroundMar4')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
%%
figure(10);
plot(median(cellInfMar4.max5./cellInfMar4.median)')
%% Plot cells post stimulus 
figure(10);
tempData=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)./cellInfMar4.median(:,switchTimeMar4:endTimeMar4));
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
temp=cellInfMar4.median;
figure(10);imshow(temp,[]);colormap(jet);
xlabel('time (h)')
%%
temp=(cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)./cellInfMar4.median(:,switchTimeMar4:endTimeMar4));
figure(11);imshow(temp,[]);colormap(jet);
%%
%% Pretty Kymograph
temp=cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)./cellInfMar4.median(:,switchTimeMar4:endTimeMar4);
m=median(temp(:,25:28),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=smooth(temp(loc(i),:),1);
end
figure(11);imshow(temp2,[1 5]);colormap(jet);impixelinfo
%%
%% single cell examples
tempD=temp2([1 5 20 40 45],:)';
figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([-2 2 1 5]);
xlabel('time (hours)'); ylabel('Nuclear localization (AU)');title('18 hour old cells experiencing glucose limitation')
%% Pretty Kymograph cells normalized to intensity
temp=cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)./cellInfMar4.median(:,switchTimeMar4:endTimeMar4);
m=median(temp(:,25:28),2);
[val loc]=sort(m,'descend');
temp2=[];
for i=1:size(temp,1)
    temp2(i,:)=temp(loc(i),:);
    temp2(i,:)=temp2(i,:)/max(temp2(i,:));

end
figure(11);imshow(temp2,[]);colormap(jet);



%%
temp=cExperimentMar4.cellInf(1).mean(cellsPresentMar4,:);
numcells=sum(temp>0);
figure(99);plot(numcells);axis([0 length(temp) 0 max(numcells)]);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperimentMar4.cellInf(channel).mean,2);
for cell=1:size(cExperimentMar4.cellInf(channel).mean,1)
    meancell=cExperimentMar4.cellInf(channel).mean(cell,:);
    max5cell=cExperimentMar4.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 60e3]);
    pause(2);
end
