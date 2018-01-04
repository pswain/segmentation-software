%For cropping data post-extraction - uses the extracted cell information in cExperiment.cellInf 
numCells=size(cExperiment.cellInf(1).median,1);
numTp=size(cExperiment.cellInf(1).median,2);

cropData=cExperiment.cellInf(1).median;
cropData(isnan(cropData))=0;
notZero=cropData>0;
notZero(:,end+1)=0;
zeroLine=[zeros(size(notZero,1),1) notZero];
zeroLine(:,end)=[];
longestRun=zeros(size(notZero,1),1);
for n=1:size(notZero,1)
    runEnds=find(notZero(n,:)-zeroLine(n,:));
    runLengths=diff(runEnds);
    nonZeroRuns=1:2:length(runLengths);   
    longestRun(n)=max(runLengths(nonZeroRuns))-1;
end



% numNz=zeros(numCells,1);
% for n=1:numCells
%     numNz(n)=nnz(cExperiment.cellInf(1).median(n,:));    
% end

%Then can get data for cells present for eg, 4/5 of the timelapse
pHluorinPositions = cExperiment.cellInf(1).posNum<35;

mediansCropped1=cExperiment.cellInf(1).median(longestRun>.8*numTp & pHluorinPositions',:);
mediansToDelete1=zeros(length(mediansCropped1));
sizeMedians=size(mediansCropped1);
for n=1:sizeMedians(1)
    meanToProcess=mean(mediansCropped1(n,:));
    if meanToProcess>GFPWTMean-100 & meanToProcess<GFPWTMean+100
        mediansToDelete1(n)=1;
    else
        mediansToDelete1(n)=0;
    end
end
mediansCropped1(mediansToDelete1,:)=[];

mediansCropped2=cExperiment.cellInf(2).median(longestRun>.8*numTp & pHluorinPositions',:);
mediansToDelete2=zeros(length(mediansCropped2));
for n=1:sizeMedians(1)
    meanToProcess=mean(mediansCropped2(n,:));
    if meanToProcess>GFPWTMean-100 & meanToProcess<GFPWTMean+100
        mediansToDelete2(n)=1;
    else
        mediansToDelete2(n)=0;
    end
end
mediansCropped2(mediansToDelete2,:)=[];

% nanMediansCropped1=isnan(mediansCropped1);
% mediansCropped2(nanMediansCropped1)=NaN;
% nanMediansCropped2=isnan(mediansCropped2);
% mediansCropped1(nanMediansCropped2)=NaN;


%% remove cells from wild type positions
%In this case wt positions are positions 36-45
%pHluorinPositions = cExperiment.cellInf(1).posNum<35;

% pHluorinMediansCropped1=cExperiment.cellInf(1).median(longestRun>.8*numTp & pHluorinPositions',:);

% pHluorinMediansCropped2=cExperiment.cellInf(2).median(longestRun>.8*numTp & pHluorinPositions',:);


%% Plotting
ratiopH=mediansCropped2./mediansCropped1;
cellpH=ratiopH*3.1+4.75;
time=1:5:1000;
figure;
plot(time,cellpH);
meanpH=nanmean(cellpH);
hold on
meanLine=plot(time,meanpH);
set (meanLine,'LineWidth',2)
set (meanLine,'Color',[0 0 0])
title('pH per cell')
ylabel('pH')
xlabel('minutes')
figure;
plot(time,meanpH);
title('mean pH')
ylabel('pH')
xlabel('minutes')

%% test
trimmed=cellpH(:,100)<5.25 & cellpH(:,1)<5.4;
figure;
plot(time,cellpH(trimmed,:))
hold on
meanpHtr=nanmean(cellpH(trimmed,:));
meanLine2=plot(time,meanpHtr);
set (meanLine2,'LineWidth',2)
set (meanLine2,'Color',[0 0 0])
title('pH per cell')
ylabel('pH')
xlabel('minutes')
figure;
plot(time,meanpHtr);
title('mean pH')
ylabel('pH')
xlabel('minutes')

