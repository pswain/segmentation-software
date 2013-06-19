%% 18 hour cell traces
cExperiment18h=cExperiment;
clear cExperiment;
%%
cExperiment18h.correctSkippedFramesInf
loc18h=min(cExperiment18h.cellInf(1).smallmean(:,30:340),[],2)>0 & max(cExperiment18h.cellInf(2).smallmean(:,50:340),[],2)>10e3 ...
    & max(diff(cExperiment18h.cellInf(2).smallmean(:,50:340),2,2),[],2)<2e4;
galMed_18h=[];numCells=[];error18h=[];
for i=1:size(cExperiment18h.cellInf(2).median,2)
    cellsPres=cExperiment18h.cellInf(1).smallmean(:,i)>0;
    cellsPres=loc18h;
    galMed_18h(i,:)=mean(cExperiment18h.cellInf(2).smallmedian(cellsPres,i));
    numCells(i)=sum(cellsPres);
    error18h(i)=sqrt(galMed_18h(i,:));

end

lengthGal18=sum(galMed_18h>0);

figure(12);plot(galMed_18h);
figure(13);plot(numCells);

figure(14);imshow(cExperiment18h.cellInf(2).smallmedian(loc18h,1:340),[]);colormap(jet);impixelinfo

data=cExperiment18h.cellInf(2).smallmedian(loc18h,191:191+149);
d=pdist(data,'cityblock');
z=squareform(d);
dataOrdered18h=[];
[v cellToCluster]=max(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered18h(i,:)=data(loc,:);
    z(loc,:)=Inf;
end
figure(11);imshow(dataOrdered18h,[0 65e3]);colormap(jet);impixelinfo 
%%

indCellMax=max(dataOrdered18h,[],2);
indMaxMat=repmat(indCellMax,1,size(dataOrdered18h,2));
halfMax=dataOrdered18h>indMaxMat/2;
halfMax=[];
for i=1:length(indCellMax)
    ind=find(dataOrdered18h(i,:)>indCellMax(i)/2);
    halfMax(i)=min(ind);
end
figure(123);hist(halfMax);

%%
%% 18 hour cell traces
cExperiment2h=cExperiment;
clear cExperiment;
%%
%% 2h plotting
cExperiment2h.correctSkippedFramesInf

loc2h=min(cExperiment2h.cellInf(1).smallmean(:,20:150),[],2)& max(cExperiment2h.cellInf(2).smallmean(:,20:150),[],2)>10e3 & ...
         max(diff(cExperiment2h.cellInf(2).smallmean(:,20:150),2,2),[],2)<2e4;

galMed_2h=[];numCells=[];error2h=[];galOn2h=[];
for i=1:size(cExperiment2h.cellInf(2).median,2)
    cellsPres=cExperiment2h.cellInf(1).smallmean(:,i)>0;
    cellsPres=loc2h;
    galMed_2h(i,:)=mean(cExperiment2h.cellInf(2).smallmedian(cellsPres,i));
%     galOn2h(i,:)=
    numCells(i)=sum(cellsPres);
    error2h(i)=sqrt(galMed_2h(i,:));
end

figure(12);plot(galMed_2h);
figure(13);plot(numCells);

figure(14);imshow(cExperiment2h.cellInf(2).smallmedian(loc2h,1:150),[]);colormap(jet);
data=cExperiment2h.cellInf(2).smallmedian(loc2h,1:1+149);
d=pdist(data,'seuclidean');
z=squareform(d);
dataOrdered2h=[];
[v cellToCluster]=max(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered2h(i,:)=data(loc,:);
    z(loc,:)=Inf;
end

figure(11);imshow(dataOrdered2h,[0 65e3]);colormap(jet);impixelinfo 

%%

indCellMax=max(dataOrdered2h,[],2);
indCellMin=min(dataOrdered2h,[],2);
halfMax2h=[];
for i=1:length(indCellMax)
    t=dataOrdered2h(i,1:24);
    tempMin=mean(t(t>0));
        t=dataOrdered2h(i,:);
    ind=find(t> ((indCellMax(i)-tempMin)/2+tempMin));
    halfMax2h(i)=min(ind);
end

indCellMax=max(dataOrdered18h,[],2);
halfMax18h=[];
for i=1:length(indCellMax)
    t=dataOrdered18h(i,1:24);
    tempMin=mean(t(t>0));
    t=dataOrdered18h(i,:);
    ind=find(t> ((indCellMax(i)-tempMin)/2+tempMin));
    halfMax18h(i)=min(ind);
end

[n2h, xout]=hist(halfMax2h,15);
[n18h, xout]=hist(halfMax18h,xout);

figure(123);bar(xout,[n18h',n2h']);
legend('18 hour','2 hour');

%%

[f2h,xi] = ksdensity(halfMax2h,24:130);
[f18h] = ksdensity(halfMax18h,xi);
xi=xi/12;
xi=xi-2;

figure(124);plot([xi',xi'],[f18h',f2h']);
legend('18 hour','2 hour');
xlabel('time post switch (hours)');
ylabel('fraction of cells');

[h,p ]=kstest2(f2h,f18h)

%%
v18=f18h.*xi;
v2=f2h.*xi;
v2=halfMax2h;
v18=halfMax18h;

std(v2)/mean(v2)
std(v18)/mean(v18)

(std(v2)/mean(v2) ) / (std(v18)/mean(v18) )
 (std(v18)/mean(v18) ) / (std(v2)/mean(v2) )

%%
numS=5;
indCellMax=max(dataOrdered2h,[],2);
indCellMin=min(dataOrdered2h,[],2);
indThresh2h=[];
cross2h=[];
nSense2h=zeros(1,size(dataOrdered2h,2));

for i=1:length(indCellMax)
    t=dataOrdered2h(i,1:24);
    tempMin=mean(t(t>0));
    t=dataOrdered2h(:,1:24);
    indThresh2h(i)=tempMin+numS*std(t(t>0));
    cross2h(i,:)=(dataOrdered2h(i,:))>indThresh2h(i);
        [a loc]=find(cross2h(i,:));
    nSense2h(min(loc))=nSense2h(min(loc))+1;

end

indCellMax=max(dataOrdered18h,[],2);
indCellMin=min(dataOrdered18h,[],2);
indThresh18h=[];cross18h=[];
nSense18h=zeros(1,size(dataOrdered18h,2));
for i=1:length(indCellMax)
    t=dataOrdered18h(i,1:24);
    tempMin=mean(t(t>0));
        t=dataOrdered2h(:,1:24);

    indThresh18h(i)=tempMin+numS*std(t(t>0));
    cross18h(i,:)=(dataOrdered18h(i,:))>indThresh18h(i);
    [a loc]=find(cross18h(i,:));
    nSense18h(min(loc))=nSense18h(min(loc))+1;
end

x=1:size(dataOrdered,2);
x=x/12;
x=x-2;
x=[x' x'];
% figure(123);plot(x,[sum(cross18h)'/size(cross18h,1) sum(cross2h)'/size(cross2h,1)]);
% legend('18h','2h');
figure(123);plot(x,[cumsum(nSense18h)'/size(cross18h,1) cumsum(nSense2h)'/size(cross2h,1)]);
legend('18h','2h');
axis([0 7 0 1])
xlabel('time post switch (hours)');
ylabel('fraction of cells');

% [a b]=find((sum(cross18h)/size(cross18h,1)) >.5);
% min(b)
% [a b]=find((sum(cross2h)/size(cross2h,1)) >.5);
% min(b)
%%
[n2h, xout]=hist(halfMax2h,15);
[n18h, xout]=hist(halfMax18h,xout);

figure(123);bar(xout,[n18h',n2h']);
legend('18 hour','2 hour');