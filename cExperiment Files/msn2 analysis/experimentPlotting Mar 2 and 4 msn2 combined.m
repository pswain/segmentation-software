%%
% figure(10);


% tempDataMar4=cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)./cellInfMar4.median(:,switchTimeMar4:endTimeMar4);

bkg=repmat(backgroundMar4(switchTimeMar4+0:endTimeMar4+0),[size(cellInfMar4.max5,1) 1]);
% bkg=smooth(ones(1,2)/2,2,bkg);
bkgMar4=smooth(bkg,2);
bkg=reshape(bkgMar4,size(bkg));
tempDataMar4=smooth((cellInfMar4.max5(:,switchTimeMar4:endTimeMar4)-bkg),2)./smooth((cellInfMar4.smallmedian(:,switchTimeMar4:endTimeMar4)-bkg),2);
tempDataMar4=reshape(tempDataMar4,size(bkg));

% tempDataMar2=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)./cellInfMar2.median(:,switchTimeMar2:endTimeMar2));
bkg=repmat(backgroundMar2(switchTimeMar2-0:endTimeMar2-0),[size(cellInfMar2.max5,1) 1]);
bkg=filter(ones(1,2)/2,1,bkg);
bkgMar2=smooth(bkg,2);
bkg=reshape(bkgMar2,size(bkg));
med=(cellInfMar2.smallmedian(:,switchTimeMar2:endTimeMar2)-bkg);
med(med<=0)=min(med(med>0));
maxim=cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg;
tempDataMar2=smooth((maxim),2)./smooth(med,2);
tempDataMar2=reshape(tempDataMar2,size(bkg));
loc=mean(tempDataMar2,2);

tempDataMar2(loc>50,:)=[];

% tempDataMar2=(cellInfMar2.max5(:,switchTimeMar2:endTimeMar2)-bkg)./med;
% tempDataMar2(isinf(tempDataMar2))=0;

% figure(123);imshow(tempDataMar2,[]);colormap(jet);impixelinfo
%
figure(9);
ratioMar4=mean(tempDataMar4);
ratioMar2=mean(tempDataMar2);
plot([ratioMar4;ratioMar2]');title('msn2 nuclear loc corrected with GFP backgroundMar2')
xlabel('timepoints');ylabel('Nuclear localization (AU)');
legend('18h','2h')

%%
figure(1);imshow(tempDataMar2,[]);colormap(jet);impixelinfo

%%
tempPlot=[median(tempDataMar2)' median(tempDataMar4)'];
error=[std(tempDataMar2)' std(tempDataMar4)'];
error=error./repmat([sqrt(size(tempDataMar2,1)) sqrt(size(tempDataMar4,1))],size(tempPlot,1),1);
% error=[error tempErrorAug26pulse3' tempErrorAug26pulse2' tempErrorAug26pulse1'];
% error(:)=0;
x=5:5:size(tempDataMar2,2)*5;
x=x/60;
x=x-2;
x=[x' x'];

% x=1:size(tempData,2);
figure(10);
errorbar(x,tempPlot,error);title('Mean nuclear localization');
xlabel('time (hours)');ylabel('Nuclear localization (AU)');
legend('2 hour (n~125)','18 hour (n~67)');
%%
figure(12);
switchTimeAug26=399-2*24;
endTimeAug26=switchTimeAug26+2.5*(length(switchTimeMar2:endTimeMar2)-1);
tpAug26=round(switchTimeAug26:2.5:endTimeAug26);
tempDataAug26pulse3=(cellInfAug26.max5(tpAug26)./cellInfAug26.median(tpAug26));
tempErrorAug26pulse3=errorAug26(tpAug26);

switchTimeAug26=208-2*24;
endTimeAug26=switchTimeAug26+2.5*(length(switchTimeMar2:endTimeMar2)-1);
tpAug26=round(switchTimeAug26:2.5:endTimeAug26);
tempDataAug26pulse2=(cellInfAug26.max5(tpAug26)./cellInfAug26.median(tpAug26));
tempErrorAug26pulse2=errorAug26(tpAug26);

switchTimeAug26=18-2*24;
endTimeAug26=switchTimeAug26+2.5*(length(switchTimeMar2:endTimeMar2)-1);
tpAug26=round(1:2.5:endTimeAug26);
tempDataAug26pulse1=(cellInfAug26.max5(tpAug26)./cellInfAug26.median(tpAug26));
tempErrorAug26pulse1=errorAug26(tpAug26);
tempDataAug26pulse1=[repmat(median(tempDataAug26pulse1),length(tempErrorAug26pulse2)-length(tempDataAug26pulse1),1); tempDataAug26pulse1];
tempErrorAug26pulse1=[repmat(median(errorAug26),length(tempErrorAug26pulse2)-length(tempErrorAug26pulse1),1)' tempErrorAug26pulse1];

tempDataMar2(10,:)=[];
tempPlot=[mean(tempDataMar2)' mean(tempDataMar4)' tempDataAug26pulse3 tempDataAug26pulse2 tempDataAug26pulse1];
error=[std(tempDataMar2)' std(tempDataMar4)'];
error=error./repmat([sqrt(size(tempDataMar2,1)) sqrt(size(tempDataMar4,1))],size(tempPlot,1),1);
error=[error tempErrorAug26pulse3' tempErrorAug26pulse2' tempErrorAug26pulse1'];
% error(:)=0;
x=5:5:size(tempDataMar2,2)*5;
x=x/60;
x=x-2;
x=[x' x' x' x' x'];

% x=1:size(tempData,2);
errorbar(x,tempPlot,error);title('Mean nuclear localization');
xlabel('time (hours)');ylabel('Nuclear localization (AU)');
legend('2 hour (n~125)','18 hour (n~67)','Triple 3rd (n~142)','Triple 2nd (n~142)','Triple 1st (n~142)');
%%

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

