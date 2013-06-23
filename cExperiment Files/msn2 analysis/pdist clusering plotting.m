

data=cExperiment.cellInf(2).max5./cExperiment.cellInf(2).smallmean;
data(isnan(data))=median(data(~isnan(data)));
data=zscore(data');
data=data';
data(10,:)=[];
d=pdist(data,'cityblock');
figure(2);imshow(data,[]);colormap(jet)
%
z=squareform(d);

figure(10);imshow(z,[])

dataOrdered=[];
for i=1:size(z,1)
    [v loc]=min(z(:,1));
    dataOrdered(i,:)=data(loc,:);
    z(loc,:)=Inf;
end

figure(11);imshow(dataOrdered,[]);colormap(jet);