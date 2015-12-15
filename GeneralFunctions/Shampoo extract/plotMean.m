
for n=1:length(data)
    t=0:5:(size(data.cumsumBirths,2)-1)*5;
    figure;errorbar(t,mean(data.cumsumBirths),std(data.cumsumBirths));
end


