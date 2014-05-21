function newData=outlierRemoval(data,outlierCutoff)

newData=[];
for i=1:size(data,2)
    temp=data(:,i);
    temp(isnan(temp))=[];
    loc=temp>0;
    [b ind]=sort(temp);
    len=length(ind);
    t=ind(end-floor(outlierCutoff*len)+1:end);
    loc(t)=0;
    t=ind(1:floor(outlierCutoff*len));
    loc(t)=0;

    newData(loc,i)=temp(loc);
end

newData(newData==0)=NaN;