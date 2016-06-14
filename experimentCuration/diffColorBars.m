function diffColorBars(numberlist, colors)
%h = bar(1,numberlist(1))
for i=1:length(numberlist)
h = bar(i,numberlist(i));
set(h,'FaceColor', colors(i,:))
hold on;
end

end