function calculateRepLifespan(cExperiment,durationCutoffFraction)

% this calculates the replicative lifespan of the mothers present in the
% experiment. It only counts mothers that are present for the duration
% fraction of the maximum mother. 

%DurationCutoffFraction can be a decimal - the fraction of the whole
%timelapse that a cell must be present, or an explicit number that is the number
% of timepoints a cell must be present for
if nargin<2
    durationCutoffFraction=.9;
end

lifespan=[];
duration=diff(cExperiment.lineageInfo.motherInfo.motherStartEnd,1,2);

numBirths=sum(cExperiment.lineageInfo.motherInfo.birthTime>0,2);

if durationCutoffFraction<1
    motherLoc=duration>(max(duration(:))*durationCutoffFraction);
else
    motherLoc=duration>(durationCutoffFraction);
end

maxBirths=numBirths(motherLoc);
for i=1:max(maxBirths)
    lifespan(i)=sum(maxBirths>i);
end

cExperiment.lineageInfo.lifespan=lifespan;