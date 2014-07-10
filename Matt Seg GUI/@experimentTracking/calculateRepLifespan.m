function calculateRepLifespan(cExperiment,durationCutoffFraction,censorCutoff)

% this calculates the replicative lifespan of the mothers present in the
% experiment. It only counts mothers that are present for the duration
% fraction of the maximum mother.

%DurationCutoffFraction can be a decimal - the fraction of the whole
%timelapse that a cell must be present, or an explicit number that is the number
% of timepoints a cell must be present for
if nargin<2
    durationCutoffFraction=.7;
end

%multiples of the median replication time a cell has to remain tracked for
%it to be considered complete ... otherwise the data is censored
if nargin<3
    censorCutoff=2.5;
end

lifespan=[];
duration=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);

%for old data to remove the lifespan curves so people aren't confused
if isfield(cExperiment.lineageInfo,'lifespan')
    cExperiment.lineageInfo=rmfield(cExperiment.lineageInfo,'lifespan');
    try
        cExperiment.lineageInfo=rmfield(cExperiment.lineageInfo,'lifespanHMM');
    end
end

if durationCutoffFraction<1
    motherLoc=duration>(max(duration(:))*durationCutoffFraction);
else
    motherLoc=duration>(durationCutoffFraction);
end

if isfield(cExperiment.lineageInfo.motherInfo,'birthTimeHMM') && ~isempty(cExperiment.lineageInfo.motherInfo.birthTimeHMM)
    numBirths=sum(cExperiment.lineageInfo.motherInfo.birthTimeHMM>0,2);
    maxBirths=numBirths(motherLoc);
    for i=1:max(maxBirths)
        lifespan(i)=sum(maxBirths>i);
    end
    
    %below calculates statistics for the RLS curves like mean/median
    %lifespan using censored data
    repTime=diff(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1,2);
    medRepTime=median(repTime(repTime>0));
    lastBirth=max(cExperiment.lineageInfo.motherInfo.birthTimeHMM,[],2);
    lastBirthToEnd=cExperiment.lineageInfo.motherInfo.motherStartEnd(:,2)-lastBirth;
    censor=lastBirthToEnd<censorCutoff*medRepTime;
    censorMother=censor(motherLoc);
    [f,x,flo,fup] = ecdf(maxBirths,'Censoring',censorMother>0,'function','survivor','alpha',.05,'bounds','on');
    %     figure(1);stairs(x,f,'LineWidth',2);title(['n= ' num2str(length(maxBirths')) ' Median births ' num2str(median(maxBirths)) ' KM median ' num2str(medianLife) ])
    
    df=abs(diff(f));
    df=[0 df'];
    kmMeanRLS=sum(df.*x')/sum(df);
    
    medianLife=find((f)<.51);
    try medianLife=medianLife(1);
    catch medianLife=NaN;end
    pd = fitdist(maxBirths,'wbl','Censoring',censorMother);
    survivalCurve=1-cdf('wbl',0:max(maxBirths)+2,pd.a,pd.b);
    meanRLSwbl=sum(abs(diff(survivalCurve)).*(1:max(maxBirths)+2));
    
    cExperiment.lineageInfo.lifespanStats.medianRLSHMM=median(maxBirths);
    cExperiment.lineageInfo.lifespanStats.meanRLSHMM=mean(maxBirths);
    cExperiment.lineageInfo.lifespanStats.medianRLSkmHMM=medianLife;
    cExperiment.lineageInfo.lifespanStats.meanRLSwblHMM=meanRLSwbl;
    cExperiment.lineageInfo.lifespanStats.meanRLSkmHMM=kmMeanRLS;
    cExperiment.lineageInfo.lifespanStats.lifespanCurveHMM=lifespan;
    cExperiment.lineageInfo.lifespanStats.lifespanCurvekmHMM=f;
    cExperiment.lineageInfo.lifespanStats.lifespanCurvekmHMM_x=x;
end

numBirths=sum(cExperiment.lineageInfo.motherInfo.birthTime>0,2);

maxBirths=numBirths(motherLoc);
for i=1:max(maxBirths)
    lifespan(i)=sum(maxBirths>i);
end

%Below calculates the states for the non-HMM lifespan curves
repTime=diff(cExperiment.lineageInfo.motherInfo.birthTime,1,2);
medRepTime=median(repTime(repTime>0));
lastBirth=max(cExperiment.lineageInfo.motherInfo.birthTime,[],2);
lastBirthToEnd=cExperiment.lineageInfo.motherInfo.motherStartEnd(:,2)-lastBirth;
censor=lastBirthToEnd<censorCutoff*medRepTime;
censorMother=censor(motherLoc);
[f,x,flo,fup] = ecdf(maxBirths,'Censoring',censorMother>0,'function','survivor','alpha',.05,'bounds','on');

df=abs(diff(f));
df=[0 df'];
kmMeanRLS=sum(df.*x')/sum(df);


medianLife=find((f)<.51);
try medianLife=medianLife(1);
catch medianLife=NaN;end
pd = fitdist(maxBirths,'wbl','Censoring',censorMother);
survivalCurve=1-cdf('wbl',0:max(maxBirths)+2,pd.a,pd.b);
meanRLSwbl=sum(abs(diff(survivalCurve)).*(1:max(maxBirths)+2));


cExperiment.lineageInfo.lifespanStats.medianRLS=median(maxBirths);
cExperiment.lineageInfo.lifespanStats.meanRLS=mean(maxBirths);
cExperiment.lineageInfo.lifespanStats.medianRLSkm=medianLife;
cExperiment.lineageInfo.lifespanStats.meanRLSwbl=meanRLSwbl;
cExperiment.lineageInfo.lifespanStats.meanRLSkm=kmMeanRLS;
cExperiment.lineageInfo.lifespanStats.lifespanCurve=lifespan;
cExperiment.lineageInfo.lifespanStats.lifespanCurvekm=f;
cExperiment.lineageInfo.lifespanStats.lifespanCurvekm_x=x;








