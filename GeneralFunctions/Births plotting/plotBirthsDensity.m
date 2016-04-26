function plotBirthsDensity(data)
%Input data is cExperiment.lineageInfo.dataForPlot (after running
%compileBirthsForPlot)

%Creates density plot of the distributions of cumulative births vs time

tps=-1:.1:10;
bw=1.1;%Bandwidth of kernel density function
for tp=1:size(data.cumsumBirths,2)
    temp=ksdensity(data.cumsumBirths(:,tp)',tps,'bandwidth',bw);
    kdBirths(:,tp)=temp;
end

nVal=num2str(size(data.cumsumBirths,1));
figure;imshow(flipud(kdBirths),[]);colormap(jet)


%For data normalized to the number of cumulative births at a given
%timepoint (eg when a drug is added)
refTp=60;
for c=1:size(data.cumsumBirths,1)
        %Number of births when the drug is added
        ageAtDrug=data.cumsumBirths(c,refTp);
        a=data.cumsumBirths(c,refTp:end);
        a=a-ageAtDrug;
        data.normCumsum(c,:)=a;    
end


kdBirths=[];
tps=-1:.1:10;
bw=1.1;%Bandwidth of kernel density function
for tp=1:size(data.normCumsum,2)
    temp=ksdensity(data.normCumsum(:,tp)',tps,'bandwidth',bw);
    kdBirths(:,tp)=temp;
end

nVal=num2str(size(data.normCumsum,1));
figure(expNum);imshow(flipud(kdBirths),[]);colormap(jet)

