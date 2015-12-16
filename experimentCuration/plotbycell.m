
function plotbycell(obj, color)
for k=1:size(obj, 1)
plot(obj(k,:), 'Color', color)
hold('on')
end
hold('off')
end