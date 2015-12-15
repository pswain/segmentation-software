%Plotnorm60 - plots the cumulated sums of cell divisions from time point 60
%- the addition of the ZpT drug - all cells normalized to zero divisions at
%that time point.

%loop through the datasets
%for n=1:length(data)
    %Loop through the cells
    for c=1:size(data.cumsumBirths,1)
        %Number of births when the drug is added
        ageAtDrug=data.cumsumBirths(c,60);
        a=data.cumsumBirths(c,60:end);
        a=a-ageAtDrug;
        data.normCumsum(c,:)=a;    
    end
%end