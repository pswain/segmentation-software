%To plot the distributions of cumulative births vs time. Normalized to the
%time when drug is added (all cells to zero births at that point)

kdBirths=[];
tps=-1:.1:10;
bw=1.1;%Bandwidth of kernel density function
for tp=1:size(data.normCumsum,2)
    temp=ksdensity(data.normCumsum(:,tp)',tps,'bandwidth',bw);
    kdBirths(:,tp)=temp;
end

nVal=num2str(size(data.normCumsum,1));
figure(expNum);imshow(flipud(kdBirths),[]);colormap(jet)