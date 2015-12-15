%Creates density plot of the distributions of cumulative births vs time

tps=-1:.1:10;
bw=1.1;%Bandwidth of kernel density function
for tp=1:size(data.cumsumBirths,2)
    temp=ksdensity(data.cumsumBirths(:,tp)',tps,'bandwidth',bw);
    kdBirths(:,tp)=temp;
end

nVal=num2str(size(data.cumsumBirths,1));
figure;imshow(flipud(kdBirths),[]);colormap(jet)