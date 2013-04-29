



cExperiment.correctSkippedFramesInf
%%
figure(12);imshow(cExperiment.cellInf(2).smallmedian,[]);

%%


galMed_18h=[];
numCells=[];
for i=1:size(cExperiment.cellInf(2).median,2)
    cellsPres=cExperiment.cellInf(1).smallmean(:,i)>0;
    galMed_18h(i,:)=median(cExperiment.cellInf(2).smallmedian(cellsPres,i));
    numCells(i)=sum(cellsPres);
end

lengthGal18=sum(galMed_18h>0);

figure(12);plot(galMed_18h);
figure(13);plot(numCells);

%%

cExperiment.correctSkippedFramesInf

%%


galMed_2h=[];
numCells=[];
for i=1:size(cExperiment.cellInf(2).median,2)
    cellsPres=cExperiment.cellInf(1).smallmean(:,i)>0;
    galMed_2h(i,:)=median(cExperiment.cellInf(2).smallmedian(cellsPres,i));
    numCells(i)=sum(cellsPres);
end

figure(12);plot(galMed_2h);
figure(13);plot(numCells);
%%

galMed_2h=[];
numCells=[];
for i=1:size(cExperiment.cellInf(2).median,2)
    cellsPres=cExperiment.cellInf(1).smallmean(:,i)>0;
    galMed_2h(i,:)=median(cExperiment.cellInf(2).smallmedian(cellsPres,i));
    numCells(i)=sum(cellsPres);
end

figure(12);imshow(cExperiment.cellInf(2).smallmedian,[]);
figure(13);plot(numCells);
%%
galMed=[];
galMed(:,1)=galMed_18h(galMed_18h>0);
galMed(:,2)=galMed_2h(1:lengthGal18);

figure(14);plot(galMed);legend('18 hour','2 hour')