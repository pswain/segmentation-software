function correctSkippedFramesInf(cTimelapse)



for j=1:length(cTimelapse.extractedData)
    d=abs(diff(cTimelapse.extractedData(j).xloc,1,2));
    dPre=d;dPre=padarray(dPre,[0 1],0,'post');
    dPost=d;dPost=padarray(dPost,[0 1],0,'pre');
    
    dPre=cTimelapse.extractedData(j).xloc(:,1:end-1)>0;
    dPre=padarray(dPre,[0 1],0,'post');
    dPost=cTimelapse.extractedData(j).xloc(:,2:end)>0;
    dPost=padarray(dPost,[0 1],0,'pre');

    
    locSkipped=(dPost>0)&(dPre>0)& (cTimelapse.extractedData(j).xloc==0);
    [row col]=find(locSkipped);
    
    for k=1:length(row)
        l=k;
        temp=cTimelapse.extractedData(j).mean;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).mean=temp;
        
        temp=cTimelapse.extractedData(j).median;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).median=temp;
        
        temp=cTimelapse.extractedData(j).max5;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).max5=temp;
        
        temp=cTimelapse.extractedData(j).std;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).std=temp;
        
        temp=cTimelapse.extractedData(j).radius;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).radius=temp;
        
        temp=cTimelapse.extractedData(j).xloc;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).xloc=temp;
        
        temp=cTimelapse.extractedData(j).yloc;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).yloc=temp;

        
        temp=cTimelapse.extractedData(j).smallmean;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).smallmean=temp;
        
        temp=cTimelapse.extractedData(j).smallmedian;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).smallmedian=temp;
        
        temp=cTimelapse.extractedData(j).smallmax5;
        temp(row(k),col(l))=(temp(row(k),col(l)-1)+temp(row(k),col(l)+1))/2;
        cTimelapse.extractedData(j).smallmax5=temp;

    end
end
