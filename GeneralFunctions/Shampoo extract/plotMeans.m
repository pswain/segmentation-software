
for n=1:length(data)
    t=0:5:(size(data{n}.normCumsum,2)-1)*5;
    figure;errorbar(t,mean(data{n}.normCumsum),std(data{n}.normCumsum));
end


