function [data, dataPlot,tpX]=plot3chSteps(tetStepInfo,fileIndex,needSeparate,params)

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
    vRThresh=.95;
else
    useNucTag=params.useNucTag;
    useRadFL=params.useRadFL;
    gfpCh=params.gfpCh;
    mChCh=params.mChCh;
    cy5Ch=params.cy5Ch;
    bbFactor=params.bbFactor;
    radSmallThresh=params.radSmallThresh;
    radLargeThresh=params.radLargeThresh;
    vRThresh=params.vRThresh;
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
    dataPlot=[];
    for strainInd=1:nStrains
        load([tetStepInfo{currFileInd}.rootFolder tetStepInfo{currFileInd}.folder filesep tags{strainInd} filesep 'cExperiment.mat']);
        
        if useRadFL
            data(strainInd).radius=full(cExperiment.cellInf(1).radiusFL);
        else
            data(strainInd).radius=full(cExperiment.cellInf(1).radius);
        end
        
        if all(data(strainInd).radius==0)
            if ~isempty(cExperiment.cellInf(1).radius)
                data(strainInd).radius=full(cExperiment.cellInf(1).radius);
            else
                data(strainInd).radius=full(cExperiment.cellInf(2).radius);
            end
        end
        data(strainInd).radius(data(strainInd).radius==0)=NaN;
        
        if useNucTag
            data(strainInd).nucLoc=cExperiment.cellInf(gfpCh).nuclearTagLoc;
        else
            data(strainInd).nucLoc=cExperiment.cellInf(gfpCh).max5./cExperiment.cellInf(gfpCh).median;
        end
        data(strainInd).nucLoc(data(strainInd).nucLoc==0)=NaN;
        data(strainInd).nucLoc(data(strainInd).nucLoc==Inf)=NaN;
        factor=data(strainInd).nucLoc(:,tSwitch-bbFactor:tSwitch-1);
        factor=nanmean(factor,2);
        data(strainInd).nucLocNorm=data(strainInd).nucLoc(:,:)./repmat(factor,[1 size(data(strainInd).nucLoc,2)])-1;
        
        minRad=min(data(strainInd).radius(:,tSwitch:tSwitch+3),[],2);
        meanRad=nanmean(data(strainInd).radius(:,tSwitch-3:tSwitch),2);
        maxNuc=max(data(strainInd).nucLocNorm(:,tSwitch+1:tSwitch+4),[],2);
        meanGFP=nanmean(cExperiment.cellInf(gfpCh).median(:,tSwitch-3:tSwitch),2);
        maxGFP=nanmean(cExperiment.cellInf(gfpCh).max5(:,tSwitch:tSwitch+4),2);
        if ~isempty(cExperiment.cellInf(gfpCh).imBackground)
            meanGFPbkg=nanmean(nanmean(cExperiment.cellInf(gfpCh).imBackground(:,tSwitch-3:tSwitch),2));
        else
            meanGFPbkg=1;
        end
        locCells=minRad<meanRad;
        locCells=locCells & minRad<.9* meanRad;
        locCells=locCells & maxGFP>meanGFP*1.4;
        locCells=locCells & meanGFP>  1.5*meanGFPbkg;
        locCells=locCells & max(isnan(data(strainInd).radius(:,tSwitch-bbFactor-2:35)),[],2)<1;
        
        locCells=locCells & meanRad>radSmallThresh;
        locCells=locCells & meanRad<radLargeThresh;
        sum(locCells(:))
        % %         locCells=locCell;
        %
        %
        data(strainInd).nucLocNorm=data(strainInd).nucLocNorm(locCells,:);
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
    nucLocPlot=[nanmean(data(1).nucLocNorm);nanmean(data(2).nucLocNorm);nanmean(data(3).nucLocNorm)];
    dataPlot.nucLocPlot=nucLocPlot;
    %         nucLocPlot=[nanmean(data(1).nucLoc);nanmean(data(2).nucLoc);nanmean(data(3).nucLoc)];
    
    %     nucLocPlot=[nanmedian(data(1).nucLocNorm);nanmedian(data(2).nucLocNorm);nanmedian(data(3).nucLocNorm)];
    
    if isfield(cExperiment.cellInf(1),'syncTimes')
        tpX=cExperiment.cellInf(1).syncTimes(1:size(nucLocPlot,2));
    else
        tpX=1:2:size(nucLocPlot,2)*2;
    end
    % tpX(end+1)=tpX(end)+tpX(end)-tpX(end-1);
    if true
        tpX=repmat(tpX,3,1);
        subplot(2,2,1);plot(tpX',nucLocPlot');legend(tetStepInfo{currFileInd}.tags);
        ylim([-.1 .6]);
        xlim([0 max(tpX(:))-20]);
        title('Norm Nuc Loc');
        nucLocPlot=[(data(1).env);(data(2).env);(data(3).env)];
        subplot(2,2,2);plot(nucLocPlot');    xlim([0 max(tpX(:))-20]);
        title('cy5 Switch');
        
        nucLocPlot=[nanmean(data(1).volumeNorm);nanmean(data(2).volumeNorm);nanmean(data(3).volumeNorm)];
        dataPlot.volumeNorm=nucLocPlot;
        subplot(2,2,3);plot(tpX',nucLocPlot');    xlim([0 max(tpX(:))-20]);   title('Normalized Volume Hough');
        ylim([.6 1.3]);
        
        nucLocPlot=[nanmean(data(1).radiusNorm);nanmean(data(2).radiusNorm);nanmean(data(3).radiusNorm)];
        dataPlot.radiusNorm=nucLocPlot;
        subplot(2,2,4);plot(tpX',nucLocPlot');    xlim([0 max(tpX(:))]);title('Norm radius Hough');
        tpX=tpX(1,:);
        
        sSpan=3;nRThresh=.02;
        nRThresh2=.1;dNucAdaptThresh=0;medNucbb=15;
        sNucLoc=smooth(nanmean(data(1).nucLocNorm),sSpan);
        tAdaptPrelim=diff(sNucLoc)>dNucAdaptThresh;tAdaptPrelim(1:tSwitch+6)=0;
        tAdaptPrelim=find(tAdaptPrelim,1,'first');
        tEndNum=min(tAdaptPrelim+medNucbb,length(sNucLoc));
        medAdaptNucLoc=median(sNucLoc(tAdaptPrelim:tEndNum));
        tt=(max(sNucLoc)-medAdaptNucLoc)*nRThresh2;%tt=max(tt,.02);
        data(1).nucRecovered=(sNucLoc-medAdaptNucLoc)<=tt;
        data(1).nucRecovered(1:tSwitch+3)=0;
        sNucLoc=smooth(nanmean(data(2).nucLocNorm),sSpan);
        tAdaptPrelim=diff(sNucLoc)>dNucAdaptThresh;tAdaptPrelim(1:tSwitch+6)=0;
        tAdaptPrelim=find(tAdaptPrelim,1,'first');
        tEndNum=min(tAdaptPrelim+medNucbb,length(sNucLoc));
        medAdaptNucLoc=median(sNucLoc(tAdaptPrelim:tEndNum));
        tt=(max(sNucLoc)-medAdaptNucLoc)*nRThresh2;%tt=max(tt,.02);
        data(2).nucRecovered=(sNucLoc-medAdaptNucLoc)<=tt;
        data(2).nucRecovered(1:tSwitch+3)=0;
        sNucLoc=smooth(nanmean(data(3).nucLocNorm),sSpan);
        tAdaptPrelim=diff(sNucLoc)>dNucAdaptThresh;tAdaptPrelim(1:tSwitch+6)=0;
        tAdaptPrelim=find(tAdaptPrelim,1,'first');
        tEndNum=min(tAdaptPrelim+medNucbb,length(sNucLoc));
        medAdaptNucLoc=median(sNucLoc(tAdaptPrelim:tEndNum));
        tt=(max(sNucLoc)-medAdaptNucLoc)*nRThresh2;%tt=max(tt,.02);
        data(3).nucRecovered=(sNucLoc-medAdaptNucLoc)<=tt;
        data(3).nucRecovered(1:tSwitch+3)=0;
        %
        %     data(1).nucRecovered=smooth(nanmean(data(1).nucLocNorm),sSpan)<nRThresh;data(1).nucRecovered(1:tSwitch+3)=0;
        %     data(2).nucRecovered=smooth(nanmean(data(2).nucLocNorm),sSpan)<nRThresh;data(2).nucRecovered(1:tSwitch+3)=0;
        %     data(3).nucRecovered=smooth(nanmean(data(3).nucLocNorm),sSpan)<nRThresh;data(3).nucRecovered(1:tSwitch+3)=0;
        data(1).nucRecoveredT=tpX(min(find(data(1).nucRecovered)))-tpX(tSwitch);
        data(2).nucRecoveredT=tpX(min(find(data(2).nucRecovered)))-tpX(tSwitch);
        data(3).nucRecoveredT=tpX(min(find(data(3).nucRecovered)))-tpX(tSwitch);
        
        
        sSpan=3;
        data(1).volumeRecovered=smooth(nanmean(data(1).volumeNorm),sSpan)>vRThresh;data(1).volumeRecovered(1:tSwitch+2)=0;
        data(2).volumeRecovered=smooth(nanmean(data(2).volumeNorm),sSpan)>vRThresh;data(2).volumeRecovered(1:tSwitch+2)=0;
        data(3).volumeRecovered=smooth(nanmean(data(3).volumeNorm),sSpan)>vRThresh;data(3).volumeRecovered(1:tSwitch+2)=0;
        data(1).volumeRecoveredT=tpX(min(find(data(1).volumeRecovered)))-tpX(tSwitch);
        data(2).volumeRecoveredT=tpX(min(find(data(2).volumeRecovered)))-tpX(tSwitch);
        data(3).volumeRecoveredT=tpX(min(find(data(3).volumeRecovered)))-tpX(tSwitch);
        %     subplot(2,2,4); bar(diag([data(:).volumeRecoveredT]),'stacked');  title('Time to Recovery');
        b=[data(:).volumeRecoveredT];c=[data(:).nucRecoveredT];
        dataPlot.volumeRecoveredT=b;
        dataPlot.nucRecoveredT=c;
        
        subplot(2,2,4); bar([b ;c]);  title('Time to Recovery');%legend('VolumeRecovery','HOG Recovery')
        set(gca,'XTickLabel',{'VolumeRecovery','HOG Recovery'})
        ylim([1 45]);
        pause(.1);
        tempFileName=[tetStepInfo{currFileInd}.folder '-plot.png'];
        print(tempFileName,'-dpng');
    end
end
