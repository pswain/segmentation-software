function [D2radii] = second_derivative_snake(radii)
%function [D2radii] = second_derivative_snake(radii)

%calculate second derivative of points radii (D^2 r / D (theta) ^2)
%radii is expected to be an unlooped list (i.e. a list of unrepeated,
%evenly spaced radii.

radii = [radii(end,:); radii; radii(1,:)];
mask = [-1; 2; -1];

D2radii = conv2(radii,mask,'valid');


end