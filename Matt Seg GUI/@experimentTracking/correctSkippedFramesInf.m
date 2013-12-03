function correctSkippedFramesInf(cExperiment)

for nSkip=1:1
    for channel=1:length(cExperiment.cellInf)
        d=abs(diff(cExperiment.cellInf(channel).mean,nSkip,2));
        dPre=d;dPre=padarray(dPre,[0 nSkip],0,'post');
        dPost=d;dPost=padarray(dPost,[0 nSkip],0,'pre');
        locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(channel).mean==0);
        
        locSkippedPre=padarray(locSkipped,[0 nSkip],0,'post');
        locSkippedPre=locSkippedPre(:,nSkip+1:end);
        locSkippedPost=padarray(locSkipped,[0 nSkip],0,'pre');
        locSkippedPost=locSkippedPost(:,1:end-nSkip);
        
        temp=(cExperiment.cellInf(channel).mean(locSkippedPre)+cExperiment.cellInf(channel).mean(locSkippedPost))./2;
        cExperiment.cellInf(channel).mean(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).median(locSkippedPre)+cExperiment.cellInf(channel).median(locSkippedPost))./2;
        cExperiment.cellInf(channel).median(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).max5(locSkippedPre)+cExperiment.cellInf(channel).max5(locSkippedPost))./2;
        cExperiment.cellInf(channel).max5(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).std(locSkippedPre)+cExperiment.cellInf(channel).std(locSkippedPost))./2;
        cExperiment.cellInf(channel).std(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).radius(locSkippedPre)+cExperiment.cellInf(channel).radius(locSkippedPost))./2;
        cExperiment.cellInf(channel).radius(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).smallmean(locSkippedPre)+cExperiment.cellInf(channel).smallmean(locSkippedPost))./2;
        cExperiment.cellInf(channel).smallmean(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).smallmedian(locSkippedPre)+cExperiment.cellInf(channel).smallmedian(locSkippedPost))./2;
        cExperiment.cellInf(channel).smallmedian(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).smallmax5(locSkippedPre)+cExperiment.cellInf(channel).smallmax5(locSkippedPost))./2;
        cExperiment.cellInf(channel).smallmax5(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).min(locSkippedPre)+cExperiment.cellInf(channel).min(locSkippedPost))./2;
        cExperiment.cellInf(channel).min(locSkipped)=temp;
        
        temp=(cExperiment.cellInf(channel).imBackground(locSkippedPre)+cExperiment.cellInf(channel).imBackground(locSkippedPost))./2;
        cExperiment.cellInf(channel).imBackground(locSkipped)=temp;
        
        
    end
end
fprintf('Finished skipped frames \n');

for j=1:length(cExperiment.cellInf)
    channel=j;
    for nSkip=2:4;
        d=abs(diff(cExperiment.cellInf(channel).mean,nSkip,2));
        dPre=d;dPre=padarray(dPre,[0 nSkip],0,'post');
        dPost=d;dPost=padarray(dPost,[0 nSkip],0,'pre');
        
        locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(channel).mean==0);
        [row col]=find(locSkipped);
        
        
        for k=1:length(row)
            k
            l=k;
            temp=cExperiment.cellInf(j).mean;
            x=[1 nSkip*2+1]; xi=1:nSkip*2+1;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).mean=temp;
            
            temp=cExperiment.cellInf(j).median;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).median=temp;
            
            temp=cExperiment.cellInf(j).max5;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).max5=temp;
            
            temp=cExperiment.cellInf(j).std;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).std=temp;
            
            temp=cExperiment.cellInf(j).radius;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).radius=temp;
            
            
            temp=cExperiment.cellInf(j).smallmean;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).smallmean=temp;
            
            temp=cExperiment.cellInf(j).smallmedian;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).smallmedian=temp;
            
            temp=cExperiment.cellInf(j).smallmax5;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).smallmax5=temp;
            
            temp=cExperiment.cellInf(j).min;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).min=temp;
            
            temp=cExperiment.cellInf(j).imBackground;
            y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
            temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
            cExperiment.cellInf(j).imBackground=temp;
            
            
        end
    end
end
