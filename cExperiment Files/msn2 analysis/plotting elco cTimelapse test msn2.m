%% make sure cells are present after stimulus
cTimelapseELCO.correctSkippedFramesInf
channel=2;
switchTimeElco=3;
endTimeElco=switchTimeElco+4;
temp=cTimelapseELCO.extractedData(1).mean;
temp=temp(:,switchTimeElco:endTimeElco);

cellsPresentElco=min(temp')>0;

% temp=cExperimentElco.cellInf(2).median;
% temp=temp(:,30:endTimeElco);
% cellsPresent2=max(temp')>10;
% cellsPresentElco=cellsPresentElco&cellsPresent2;

cellInfElco=cTimelapseELCO.extractedData(channel);

%%
cTimelapseMATT.correctSkippedFramesInf

channel=2;
switchTimeMatt=3;
endTimeMatt=switchTimeMatt+4;
temp=cTimelapseMATT.extractedData(1).mean;
temp=temp(:,switchTimeMatt:endTimeMatt);

cellsPresentMatt=min(temp')>0;

% temp=cExperimentMatt.cellInf(2).median;
% temp=temp(:,30:endTimeMatt);
% cellsPresent2=max(temp')>10;
% cellsPresentMatt=cellsPresentMatt&cellsPresent2;

cellInfMatt=cTimelapseMATT.extractedData(channel);
%%
eRatio=struct('max5',[],'mean',[],'median',[]);
mRatio=struct('max5',[],'mean',[],'median',[]);
for i=1:size(cellInfMatt.max5,2)
    present=cellInfMatt.max5(:,i)>0;
    eRatio.max5(i)=mean(cellInfElco.max5(present,i));
    mRatio.max5(i)=mean(cellInfMatt.max5(present,i));
    
    eRatio.mean(i)=mean(cellInfElco.mean(present,i));
    mRatio.mean(i)=mean(cellInfMatt.mean(present,i));
    
    eRatio.median(i)=mean(cellInfElco.median(present,i));
    mRatio.median(i)=mean(cellInfMatt.median(present,i));


end

figure(10);plot([eRatio.median; mRatio.median]');title('Median fluorescence intensity')
legend('elco','matt')

figure(10);plot([eRatio.median; mRatio.median]');title('Median fluorescence intensity')
legend('elco','matt')

figure(11);plot([eRatio.max5; mRatio.max5]');title('Max fluorescence intensity')
legend('elco','matt')

%%

figure(10);plot(eRatio.median-mRatio.median);
legend('elco','matt')

%%

figure(2);plot([eRatio.max5./eRatio.mean; mRatio.max5./mRatio.mean]');title('Nuclear Localization')
legend('Active Cont','Hough')
%%
meDiff=mean(eRatio.mean)-mean(mRatio.mean);
figure(3);plot([eRatio.max5./eRatio.mean; (mRatio.max5+0)./(mRatio.mean+meDiff)]');
legend('Active Cont','Hough')

figure(10);plot([eRatio.median; mRatio.median]');title('Median fluorescence intensity')
legend('Active Cont','Hough')

figure(4);plot([eRatio.max5./eRatio.median; (mRatio.max5+0)./(mRatio.median)]');title('Nuclear Localization (Max/Med)')
legend('Active Cont','Hough')


meDiff=mean(eRatio.median)-mean(mRatio.median);
figure(5);plot([eRatio.max5./eRatio.median; (mRatio.max5)./(mRatio.median+meDiff)]');title('Nuclear Localization (Max/Med) Scaled Median')
legend('Active Cont','Hough')

