function p = circleGrid_old(x,y,radius2,xCenter,yCenter,resolution)
p = x-x; % create a Zero vector with the same resolution than x
for j=0:resolution
    dy = -0.5 + j/resolution;
    for i=0:resolution
        dx = -0.5 + i/resolution;
        p = p + ((x+dx-xCenter).^2 + (y+dy-yCenter).^2 < radius2);
    end
end
p = p /(resolution+1) / (resolution+1);
end

