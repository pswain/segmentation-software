function correctSkippedFramesInf(cExperiment)

d=abs(diff(cExperiment.cellInf(1).mean,1,2));
dPre=d;dPre=padarray(dPre,[0 1],0,'post');
dPost=d;dPost=padarray(dPost,[0 1],0,'pre');

locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(1).mean==0);
[row col]=find(locSkipped);

for j=1:length(cExperiment.cellInf)
    
    for k=1:length(row)
        l=k;
        temp=cExperiment.cellInf(j).mean;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).mean=temp;
        
        temp=cExperiment.cellInf(j).median;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).median=temp;
        
        temp=cExperiment.cellInf(j).max5;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).max5=temp;
        
        temp=cExperiment.cellInf(j).std;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).std=temp;
        
        temp=cExperiment.cellInf(j).radius;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).radius=temp;
        
        
        temp=cExperiment.cellInf(j).smallmean;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).smallmean=temp;
        
        temp=cExperiment.cellInf(j).smallmedian;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).smallmedian=temp;
        
        temp=cExperiment.cellInf(j).smallmax5;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).max5=temp;
        
        temp=cExperiment.cellInf(j).min;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).min=temp;
        
        temp=cExperiment.cellInf(j).imBackground;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cExperiment.cellInf(j).imBackground=temp;


    end
end
