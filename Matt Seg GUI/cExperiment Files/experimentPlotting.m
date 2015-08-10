channel=2;
fl1=cExperiment.cellInf(channel).median;
fl2=cExperiment.cellInf(channel).mean;
fl3=cExperiment.cellInf(channel).std;

fl1new=[];fl2new=[];fl3new=[];
numcells=[];
% for i=1:size(fl1,2)
for i=1:140
    fl1new(i)=mean(fl1(fl1(:,i)>0,i));
    fl2new(i)=mean(fl2(fl2(:,i)>0,i));
    fl3new(i)=mean(fl3(fl3(:,i)>0,i));
    numcells(i)=mean(fl1(:,i)>0);
end
fl1new=smooth(fl1new,2,'moving');
fl2new=smooth(fl2new,2,'moving');
fl3new=smooth(fl3new,2,'moving');

figure(101);plot(fl1new);
figure(102);plot(fl2new);
% figure(103);plot(fl3new./fl1new);


numcells=sum(fl1>0);
figure(99);plot(numcells);axis([0 length(fl1) 0 max(numcells)]);
%%
temp=cExperiment.cellInf(channel).median(:,1:140);
figure(10);imshow(temp,[]);colormap(jet);


%% Shows movie of single cell traces

f1=figure(10);ax1=gca;
timepoints=1:size(cExperiment.cellInf(channel).mean,2);
for cell=1:size(cExperiment.cellInf(channel).mean,1)
    meancell=cExperiment.cellInf(channel).mean(cell,:);
    max5cell=cExperiment.cellInf(channel).max5(cell,:);
    plot(ax1,timepoints,meancell);xlabel('Hours');
    axis([0 max(timepoints) 0 60e3]);
    pause(2);
end
%% Shows collection of single cell traces
bob=[];
% for i=1:size(cExperiment.cellInf(channel).mean,1)
for i=1:sie(cExperiment.cellInf(channel).mean,1)z

fl1temp=fl1(i,:);
fl2temp=fl2(i,:);
fl3temp=fl3(i,:);

% fl1temp=smooth(fl1temp,2);
% fl2temp=smooth(fl2temp,2);
% fl3temp=smooth(fl3temp,2);

bob(i,:)=fl1temp;
end
% 
% for i=1:size(bob,2)
%     loc=bob(:,i)==0;
%     bob(loc,i)=median(bob(~loc,i));
% end
figure(10);imshow(bob,[]);colormap(jet);
