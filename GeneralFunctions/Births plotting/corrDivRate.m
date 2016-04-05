function data=corrDivRate(cExperiment,timerange,refTimepoint,channel)
%Correlates number of cell divisions within a range of timepoints with
%median expression level (at an input timepoint) in cells having defined birth events

%cExperiment.lineageInfo.dataForPlot must be generated by compileBirthsForPlot.m
%cExperiment should have a .cellInf field populated with data from a
%fluorescence channel (given by index channel)
%Timerange is a 2 element vector representing the starting and ending
%timepoints

data=cExperiment.lineageInfo.dataForPlot;
fieldName=[num2str(timerange(1)) 'to' num2str(timerange(2))];
%Loop through the cells
for c=1:length(data.motherIndices)
    data.median(c)=cExperiment.cellInf(channel).median(data.motherIndices(c),refTimepoint);
    data.(['births' fieldName])(c)=data.cumsumBirths(c,timerange(2))-data.cumsumBirths(c,timerange(1));    
end

%Calculate mean fluorescence values 
for numBirths=0:max(data.(['births' fieldName]))
    thisNumBirths=data.(['births' fieldName])==numBirths;
    meanFl(numBirths+1)=mean(data.median(thisNumBirths));
    sdFl(numBirths+1)=std(data.median(thisNumBirths));    
end

figure;
plot(data.(['births' fieldName]),data.median,'.');
hold on;
errorbar([0:max(data.(['births' fieldName]))],meanFl,sdFl);

%Next plot fluorescence vs time to first division after the ref timepoint
%(recovery time after withdrawal of the drug)



