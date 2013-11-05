function [radii,angles] = initialise_snake_radial(im,N,x,y,Rmin,Rmax)
%function [radii,angles] = initialise_snake_radial(im,N,x,y,Rmin,Rmax)


% Initialises the snakes with a centre at x,y in the image im.
% N      - number of snake points
% (x,y)  - centre coordinate
% Rmin   - minimal distance of cell edge from centre allowed
% Rmax   - maximum distance of cell edge from centre allowed



N = max(N,4);


% make an N+1 length vector of equally spaced angles.
angles = linspace(0,2*pi,N+1)';
angles = angles(1:N,1);
radii = zeros(size(angles));

[imY,imX] = size(im);

for i=1:N
    %loops through all the first N points (leaving out the repeated zero
    %N+1) and get the best point in the image for them.
    cordx = uint16(x+(Rmin:Rmax)'*cos(angles(i)));%radial cords
    cordy = uint16(y+(Rmin:Rmax)'*sin(angles(i)));
    
    cordx(cordx<1) = 1;
    cordx(cordx>imX) = imX;
    
    cordy(cordy<1) = 1;
    cordy(cordy>imY) = imY;
    
    
    score = zeros(size(cordx));
    for j = 1:length(score)
        score(j) = im(cordy(j),cordx(j));
    end
    
    
    [~,minIndex] = min(score);
    
    radii(i) = Rmin+minIndex-1;
    
end


end
