

data=cExperiment.cellInf(2).max5;
data(isnan(data))=median(data(~isnan(data)));
data(data==0)=min(data(data>0));
% data=zscore(data');
% data=data';
data(10,:)=[];
d=pdist(data,'cityblock');
figure(2);imshow(data,[]);colormap(jet)
%
z=squareform(d);

% figure(10);imshow(z,[])

dataOrdered=[];
[v cellToCluster]=max(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered(i,:)=data(loc,:);
    z(loc,:)=Inf;
end

figure(11);imshow(dataOrdered,[0 65e3]);colormap(jet);impixelinfo