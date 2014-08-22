function plotSizes(timelapse)
data = timelapse.extractedData;
figure;
clf;
hold on;
color = [ 'm' 'c' 'r' 'g' 'b' 'y' 'k'];
j=1;
for i=1:length(data(2).mean(:,1))%get the number of cells tracked
    
    
    plot(data(2).radius(i,:),color(j));
    j=j+1;
    if j==8
       j=1; 
    end
end
hold off;
end
