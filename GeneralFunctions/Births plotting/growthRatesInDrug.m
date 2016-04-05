function cExperiment=growthRatesInDrug(cExperiment)

%Calculates ratio of number of cell divisions per unit time with drug and without
%This script assumes that before tp60 cells are not in the drug and they
%are in the drug from tp61 to tp180
data=cExperiment.lineageInfo.dataForPlot;
for n=1:length(data)
    before=data{n}.bTime<61;
    birthsBefore=sum(sum(before));
    beforePerCellHr=birthsBefore/5/size(data{n}.bTime,1);%5 hrs before drug added
    inDrug=data{n}.bTime>61&data{n}.bTime<181;
    birthsInDrug=sum(sum(inDrug));
    inDrugPerCellHr=birthsInDrug/10/size(data{n}.bTime,1);%10 hrs in drug
    data{n}.birthsRatio=inDrugPerCellHr/beforePerCellHr;
end
cExperiment.lineageInfo.dataForPlot=data;