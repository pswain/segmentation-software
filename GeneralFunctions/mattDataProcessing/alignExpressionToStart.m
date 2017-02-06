function cVal=alignExpressionToStart(cVal)
cVal=full(cVal);
cVal(cVal==0)=NaN;cVal(cVal==Inf)=NaN;
tpNo=all(isnan(cVal));
tpNo=tpNo | all(isinf(cVal));
cVal=cVal(:,~tpNo);

for i=1:size(cVal,1)
    temp=cVal(i,:);
    if false%isnan(temp(1)) || isinf(temp(1))
        loc=find(~isnan(temp),1);
        temp(1:loc-1)=[];
%         temp=temp/temp(1);
        cVal(i,1:length(temp))=(temp);
    else
%         temp=temp/temp(1);
        cVal(i,1:length(temp))=(temp);
    end
end
