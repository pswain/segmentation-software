
%% 18 hour cell traces
cExperiment.correctSkippedFramesInf
loc18h=min(cExperiment.cellInf(1).smallmean(:,30:340),[],2)>0 & max(cExperiment.cellInf(2).smallmean(:,50:340),[],2)>10e3 ...
    & max(diff(cExperiment.cellInf(2).smallmean(:,50:340),2,2),[],2)<2e4;
galMed_18h=[];numCells=[];error18h=[];
for i=1:size(cExperiment.cellInf(2).median,2)
    cellsPres=cExperiment.cellInf(1).smallmean(:,i)>0;
    cellsPres=loc18h;
    galMed_18h(i,:)=mean(cExperiment.cellInf(2).smallmedian(cellsPres,i));
    numCells(i)=sum(cellsPres);
    error18h(i)=sqrt(galMed_18h(i,:));

end

lengthGal18=sum(galMed_18h>0);

figure(12);plot(galMed_18h);
figure(13);plot(numCells);

figure(14);imshow(cExperiment.cellInf(2).smallmedian(loc18h,1:340),[]);colormap(jet);impixelinfo

data=cExperiment.cellInf(2).smallmedian(loc18h,191:191+149);
d=pdist(data,'cityblock');
z=squareform(d);
dataOrdered=[];
[v cellToCluster]=max(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered(i,:)=data(loc,:);
    z(loc,:)=Inf;
end
figure(11);imshow(dataOrdered,[0 65e3]);colormap(jet);impixelinfo 
% figure(14);imshow(cExperiment.cellInf(2).smallmedian(loc18h,191:191+149),[]);colormap(jet);impixelinfo
background18h=[];
for i=1:size(cExperiment.cellInf(2).imBackground,2)
    background18h(:,i)=mean(cExperiment.cellInf(2).imBackground(cExperiment.cellInf(2).imBackground(:,i)>0,i));
    if find(cExperiment.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end
figure;plot(background18h);

%% Plot single cells from the 18 hour selection
temp=dataOrdered;
tempD=temp([4 13 42 90 140],:)';
for i=1:size(tempD,2);
    tempD(i,:)=smooth(tempD(i,:),5,'moving');
end
x=5:5:size(galMed,1)*5;
x=x/60;
x=x-2;

figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([0 max(x) -.5 6]);
title('Mean of median 18h cells Gal10 induction');
xlabel('time post stimulation (hours)');ylabel('Median Cell Fluorescence (AU)');
axis([-1 10 0 65e3]);
%% 2h plotting
cExperiment.correctSkippedFramesInf

loc2h=min(cExperiment.cellInf(1).smallmean(:,20:150),[],2)& max(cExperiment.cellInf(2).smallmean(:,20:150),[],2)>10e3 & ...
         max(diff(cExperiment.cellInf(2).smallmean(:,20:150),2,2),[],2)<2e4;

galMed_2h=[];numCells=[];error2h=[];galOn2h=[];
for i=1:size(cExperiment.cellInf(2).median,2)
    cellsPres=cExperiment.cellInf(1).smallmean(:,i)>0;
    cellsPres=loc2h;
    galMed_2h(i,:)=mean(cExperiment.cellInf(2).smallmedian(cellsPres,i));
%     galOn2h(i,:)=
    numCells(i)=sum(cellsPres);
    error2h(i)=sqrt(galMed_2h(i,:));
end

figure(12);plot(galMed_2h);
figure(13);plot(numCells);

figure(14);imshow(cExperiment.cellInf(2).smallmedian(loc2h,1:150),[]);colormap(jet);
data=cExperiment.cellInf(2).smallmedian(loc2h,1:1+149);
d=pdist(data,'seuclidean');
z=squareform(d);
dataOrdered=[];
[v cellToCluster]=max(mean(data,2));
for i=1:size(z,1)
    [v loc]=min(z(:,cellToCluster));
    dataOrdered(i,:)=data(loc,:);
    z(loc,:)=Inf;
end

figure(11);imshow(dataOrdered,[0 65e3]);colormap(jet);impixelinfo 

background2h=[];
for i=1:size(cExperiment.cellInf(2).imBackground,2)
    background2h(:,i)=mean(cExperiment.cellInf(2).imBackground(cExperiment.cellInf(2).imBackground(:,i)>0,i));
    if find(cExperiment.cellInf(2).imBackground(:,i)<0)
        b=1
    end
end

%% Plot single cells from the 2 hour selection
temp=dataOrdered;
tempD=temp([1 18 29 84 123],:)';
for i=1:size(tempD,2);
    tempD(i,:)=smooth(tempD(i,:),2,'moving');
end
x=5:5:size(galMed,1)*5;
x=x/60;
x=x-2;

figure(12);plot(repmat(x',[1 size(tempD,2)]),tempD);axis([0 max(x) -.5 6]);
title('Mean of median 2h cells Gal10 induction');
xlabel('time post stimulation (hours)');ylabel('Median Cell Fluorescence (AU)');
axis([-1 10 0 65e3]);

%% backgroundAug26=median(cExperimentAug26.cellInf(2).imBackground);
figure(4);
plot(background2h);title('Median non-cell Fluorescence for all traps');
hold on; plot(background18h);title('Median non-cell Fluorescence for all traps');

xlabel('timepoint');
ylabel('Fluorescence (AU)')
% backgroundAug26=median(backgroundAug26(backgroundAug26>0));
figure(11);imshow(cExperiment.cellInf(2).imBackground,[0 1e3]);colormap(jet);impixelinfo 

%%
galMed=[];
galMed(:,1)=galMed_18h(galMed_18h>0);
galMed(:,2)=galMed_2h(1:lengthGal18);
error=[];
error(:,1)=error18h(galMed_18h>0);
error(:,2)=error2h(1:lengthGal18);

figure(14);plot(galMed);legend('18 hour','2 hour')

%% error plotting 

x=5:5:size(galMed,1)*5;
x=x/60;
x=x-2;
x=[x' x'];
figure(14);
    errorbar(x,galMed,error);title('Mean of median GAL10::GFP induction');
xlabel('time post stimulation (hours)');ylabel('Median Cell Fluorescence (AU)');
legend(['20 hour (n=',num2str(sum(loc18h)),')'],['2 hour (n=',num2str(sum(loc2h)),')']);
axis([-1 10 0 25e3]);
