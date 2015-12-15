%%
figure(10);

tempDataFeb8=cellInfFeb8.median(:,switchTimeFeb8:endTimeFeb8);
tempDataFeb27=cellInfFeb27.median(:,switchTimeFeb27:endTimeFeb27); 
tempPlot=[mean(tempDataFeb8*60/65)' mean(tempDataFeb27)'];
error=[std(tempDataFeb8)' std(tempDataFeb27)'];
error=error./repmat([sqrt(size(tempDataFeb8,1)) sqrt(size(tempDataFeb27,1))],size(tempPlot,1),1);
x=5:5:size(tempDataFeb8,2)*5;
x=x/60;
x=[x' x'];
% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Mean of median GAL10::GFP induction');
xlabel('time post stimulation (hours)');ylabel('Median Cell Fluorescence (AU)');
legend('20 hour (n~160)','2 hour (n~200)');
% plot(x,tempPlot);fig

%%

m=mean(mean(cellInfFeb27.median(:,switchTimeFeb27:switchTimeFeb27+20)));
s=mean(std(cellInfFeb27.median(:,switchTimeFeb27:switchTimeFeb27+20)));
onThresh2=m+5*s;

m=mean(mean(cellInfFeb8.median(:,switchTimeFeb8:switchTimeFeb8+20)));
s=mean(std(cellInfFeb8.median(:,switchTimeFeb8:switchTimeFeb8+20)));
onThresh20=m+5*s;



fractionOn20=[];
fractionOn2=[];
for i=0:size(x,1)-1
    
numOn20=(cellInfFeb8.median(:,switchTimeFeb8+i)*60/65)>onThresh20;
fractionOn20(i+1)=sum(numOn20)/length(numOn20);

numOn2=(cellInfFeb27.median(:,switchTimeFeb27+i))>onThresh2;
fractionOn2(i+1)=sum(numOn2)/length(numOn2);

end
tempPlot=[fractionOn20' fractionOn2'];

figure(11);
plot(x,tempPlot);title('Fraction GAL10::GFP induction');
xlabel('time post stimulation (hours)');ylabel('Fraction of cells that have turned on');
legend('20 hour (n~160)','2 hour (n~200)');
axis([0 7 0 1])

%%
figure;plot(mean(cellInfFeb8.median(numOn,switchTimeFeb8:endTimeFeb8)))

numOn=max(cellInfFeb27.median(:,switchTimeFeb27:endTimeFeb27)')>onThresh;
sum(numOn)/length(numOn)
figure;plot(mean(cellInfFeb27.median(numOn,switchTimeFeb27:endTimeFeb27)))
