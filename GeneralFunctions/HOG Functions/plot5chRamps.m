function plot5chRamps(tetStepInfo,fileIndex,needSeparate,params)

if nargin<2 || isempty(fileIndex)
    fileIndex=1:length(tetStepInfo)
end
if nargin<3 || isempty(needSeparate)
    needSeparate=true;
end

if nargin<4 || isempty(params)
    useNucTag=false;
    useRadFL=false;
    gfpCh=2;
    mChCh=3;
    cy5Ch=4;
    bbFactor=4;
    radSmallThresh=7.5;
    radLargeThresh=11;
else
    useNucTag=params.useNucTag;
    useRadFL=params.useRadFL;
    gfpCh=params.gfpCh;
    mChCh=params.mChCh;
    cy5Ch=params.cy5Ch;
    bbFactor=params.bbFactor;
    radSmallThresh=params.radSmallThresh;
    radLargeThresh=params.radLargeThresh;

end



for fileInd=1:length(fileIndex)
    fileInd
    currFileInd=fileIndex(fileInd);
    tSwitch=tetStepInfo{currFileInd}.tSwitch;
    tags=tetStepInfo{currFileInd}.tags;
    nStrains=length(tags);
    if needSeparate
        load([tetStepInfo{currFileInd}.rootFolder tetStepInfo{currFileInd}.folder filesep 'cExperiment.mat']);
        syncCellTimes(cExperiment,[tetStepInfo{currFileInd}.rootFolder tetStepInfo{currFileInd}.folder filesep ...
            tetStepInfo{currFileInd}.logFile]);
        separateExperimentAll(cExperiment,nStrains,[tetStepInfo{currFileInd}.rootFolder tetStepInfo{currFileInd}.folder],tags);
    end
    
    data=[];
    for strainInd=1:nStrains
        load([tetStepInfo{currFileInd}.rootFolder tetStepInfo{currFileInd}.folder filesep tags{strainInd} filesep 'cExperiment.mat']);
        
        if useRadFL
            data(strainInd).radius=full(cExperiment.cellInf(1).radiusFL);
        else
            data(strainInd).radius=full(cExperiment.cellInf(1).radius);
        end

        if all(data(strainInd).radius==0)
            data(strainInd).radius=full(cExperiment.cellInf(1).radius);
        end
        data(strainInd).radius(data(strainInd).radius==0)=NaN;

        
        minRad=min(data(strainInd).radius(:,tSwitch:tSwitch+3),[],2);
        meanRad=nanmean(data(strainInd).radius(:,tSwitch-3:tSwitch),2);

        locCells=meanRad>radSmallThresh;
        locCells=locCells & meanRad<radLargeThresh;
        sum(locCells(:))
% %         locCells=locCell;
        if useNucTag
            data(strainInd).nucLoc=cExperiment.cellInf(gfpCh).nuclearTagLoc;
        else
            data(strainInd).nucLoc=cExperiment.cellInf(gfpCh).max5./cExperiment.cellInf(gfpCh).median;
        end
        data(strainInd).nucLoc(data(strainInd).nucLoc==0)=NaN;
        data(strainInd).nucLoc(data(strainInd).nucLoc==Inf)=NaN;
        factor=data(strainInd).nucLoc(locCells,tSwitch-bbFactor:tSwitch-1);
        factor=nanmean(factor,2);
        %
%         
        data(strainInd).nucLocNorm=data(strainInd).nucLoc(locCells,:)./repmat(factor,[1 size(data(strainInd).nucLoc,2)])-1;
%         factor=nanmean(factor);
%         data(strainInd).nucLocNorm=data(strainInd).nucLoc/factor -1;
        
        env=cExperiment.cellInf(cy5Ch).imBackground;
        env(env==0)=NaN;
        data(strainInd).env=nanmean(env);
        
        factor=data(strainInd).radius(locCells,tSwitch-bbFactor:tSwitch-1);
        factor=nanmean(factor,2);
        data(strainInd).radiusNorm=data(strainInd).radius(locCells,:)./repmat(factor,[1 size(data(strainInd).radius,2)]);
        
        data(strainInd).volume=data(strainInd).radius(locCells,:).^3 * 4/3*pi;
        
        factor=data(strainInd).volume(:,tSwitch-bbFactor:tSwitch-1);
        factor=nanmean(factor,2);
        data(strainInd).volumeNorm=data(strainInd).volume(:,:)./repmat(factor,[1 size(data(strainInd).volume,2)]);
        
        meanVol=meanRad.^3*4/3*pi;
        
%         data(strainInd).volumeRecovered=data(strainInd).volumeNorm>1;
%         data(strainInd).volumeRecovered
    end
    
    figure;title(tetStepInfo{currFileInd}.title);
%     loc1=max(data(1).nucLocNorm(locCells,tSwitch:tSwitch+10),[],2)>.2;
%     loc2=max(data(2).nucLocNorm(locCells,tSwitch:tSwitch+10),[],2)>.2;
%     loc3=max(data(3).nucLocNorm(locCells,tSwitch:tSwitch+10),[],2)>.2;

%     loc1=loc1 & nanmean(data(1).nucLocNorm(:,tSwitch:tSwitch+10),[],2)>.2;

tpX=cExperiment.cellInf(1).syncTimes;
    nucLocPlot=[];
    for tInd=1:length(tags)
        nucLocPlot(tInd,:)=nanmean(data(tInd).nucLocNorm);
    end
    subplot(2,2,1);plot(tpX,nucLocPlot');legend(tetStepInfo{currFileInd}.tags);
    ylim([-.1 .4]);
    xlim([0 100])
    title('Norm Nuc Loc');
    
    nucLocPlot=[];
    for tInd=1:length(tags)
        nucLocPlot(tInd,:)=(data(tInd).env)';
    end
    subplot(2,2,2);plot(nucLocPlot');    xlim([0 100]);
    title('cy5 Switch');

    nucLocPlot=[];
    for tInd=1:length(tags)
        nucLocPlot(tInd,:)=nanmean(data(tInd).volumeNorm);
    end
    subplot(2,2,3);plot(nucLocPlot');    xlim([0 100]);   title('Normalized Volume Hough');
    
    nucLocPlot=[];
    for tInd=1:length(tags)
        nucLocPlot(tInd,:)=nanmean(data(tInd).radiusNorm);
    end
    subplot(2,2,4);plot(nucLocPlot');    xlim([0 100]);title('Norm radius Hough');
    
    pause(.1);
    tempFileName=[tetStepInfo{currFileInd}.folder '-plot.png'];
    print(tempFileName,'-dpng');
end

  