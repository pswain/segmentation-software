
a = zeros(1,221)
cc = jet(20);
for j = 2:1:20
    figure;
    
    max = 0;
    for i = 45:120
        if max < length(cTimelapse.cTimepoint(i).trapInfo(j).cell);
            max = length(cTimelapse.cTimepoint(1).trapInfo(j).cell);
        end
    end
    for k = 1:1:max%length( cTimelapse.cTimepoint(1).trapInfo(j).cell)
        for i = 45:120%1:1:length(cTimelapse.cTimepoint)
            
            try
                a(j,i) = cTimelapse.cTimepoint(i).trapInfo(j).cell(k).cellRadius;
            catch
                a(j,i) = 0;
            end
        end
        
        hold on;
        plot(a(j,:),'color',cc(k,:));
     
    end
   
end

plot(mean(a), 'k')
