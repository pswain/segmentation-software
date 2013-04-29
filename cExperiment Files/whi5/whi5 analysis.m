%% make sure cells are present after stimulus
cExperiment.correctSkippedFramesInf
%%
h=figure(10);
for i=1:20
    data=cExperiment.cellInf(2).max5(i,:)./cExperiment.cellInf(2).median(i,:);
    plot(data);
    pause(1);
end
%%
i=13
bkg=median(cExperiment.cellInf(2).imBackground(i,:));
data=[];
data(:,1)=cExperiment.cellInf(2).max5(i,:)./cExperiment.cellInf(2).smallmedian(i,:);
data(:,2)=(cExperiment.cellInf(2).max5(i,:)-bkg) ./ (cExperiment.cellInf(2).smallmedian(i,:)-bkg);

plot(data(:,2));


plot(cExperiment.cellInf(2).max5(i,:))
% plot(cExperiment.cellInf(2).imBackground(i,:))
shg
%%
channel=2;
switchTimeElco=3;
endTimeElco=switchTimeElco+4;
temp=cExperiment.extractedData(1).mean;
temp=temp(:,switchTimeElco:endTimeElco);

cellsPresentElco=min(temp')>0;

% temp=cExperimentElco.cellInf(2).median;
% temp=temp(:,30:endTimeElco);
% cellsPresent2=max(temp')>10;
% cellsPresentElco=cellsPresentElco&cellsPresent2;

cellInf=cExperiment.extractedData(channel);

%%
eRatio=struct('max5',[],'mean',[],'median',[]);
for i=1:size(cellInfMatt.max5,2)
    present=cellInfMatt.max5(:,i)>0;
    eRatio.max5(i)=mean(cellInf.max5(present,i));
    
    eRatio.mean(i)=mean(cellInf.mean(present,i));
    
    eRatio.median(i)=mean(cellInf.median(present,i));
    
    
end

figure(10);plot([eRatio.median; mRatio.median]');title('Median fluorescence intensity')
legend('elco','matt')

figure(10);plot([eRatio.median; mRatio.median]');title('Median fluorescence intensity')
legend('elco','matt')

figure(11);plot([eRatio.max5; mRatio.max5]');title('Max fluorescence intensity')
legend('elco','matt')