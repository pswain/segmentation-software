load('/Users/mcrane2/OneDrive/timelapses/Gal/gal10 - 2h - 7 Mar 2013/cExperiment.mat')
load('/Users/mcrane2/OneDrive/timelapses/Gal/gal10 - 2h - 15 apr 2013/cExperiment.mat')
load('/Users/mcrane2/OneDrive/timelapses/Gal/gal10 - 2h - 27 Feb 2013/cExperiment.mat')
load('/Users/mcrane2/OneDrive/timelapses/Gal/gal10 - 20h - 8 Feb 2013/cExperiment.mat')

data=cExperiment.cellInf(2).max5;
data(isnan(data))=median(data(~isnan(data)));
data(data==0)=min(data(data>0));
% data=zscore(data');
% data=data';
% data(10,:)=[];
d=pdist(data,'cosine');
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