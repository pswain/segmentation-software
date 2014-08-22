function PlotData(timelapse)
data = timelapse.extractedData;
figure;
clf;
hold on;
color = [ 'm' 'c' 'r' 'g' 'b' 'y' 'k'];
j=1;
for i=1:length(data(2).mean(:,1))%get the number of cells tracked
    
    median=data(2).median(i,:);
    m5=data(2).max5(i,:);

    plot(m5./median,color(j));
    j=j+1;
    if j==8
       j=1; 
    end
end
plot(13,0:0.01:3)
hold off;
end
