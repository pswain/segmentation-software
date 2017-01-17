function [px,py] = get_full_points_from_radii(radii,angles,center,image_size)
%function [px,py] = get_full_points_from_radii(radii,angles,center,image_size)

% function to take a set of radii,angles,a center and return an unbroken
% edge of the cell with no repeats.

% radii        -   vector of radii around the cell
% angles       -   angles to the x axis at which these radii are given (clockwise
%                  is positive)
% image_size   -   size of the image in which the points should be confined.

% px           -   x coordinates of resultant end points.
% py           -   y coordinates of resultant end points.

angles = reshape(angles,length(angles),1);

radii = reshape(radii,length(radii),1);

% get dense spacing in angles to ensure all pixels the spline intersects
% are present in px,py.
pixel_diff = 0.1;
angle_diff = pixel_diff/max(radii);
steps = (0:angle_diff:(2*pi))';

%order the angles vector (may not be necessary)
[angles,indices_angles] = sort(angles,1);
radii = radii(indices_angles);

%construct spline using file exchange function 'splinefit'
r_spline = splinefit([angles; 2*pi],[radii;radii(1)],[angles; 2*pi],'p');%make the spline

radii_full = ppval(r_spline,steps);

%convert radial coords to x y coords
px = round(center(1)+radii_full.*cos(steps));%radial cords
py = round(center(2)+radii_full.*sin(steps));

%check they are sensible
px(px<1) = 1;
px(px>image_size(2)) = image_size(2);

py(py<1) = 1;
py(py>image_size(1)) = image_size(1);

%remove repeats (i.e. pixels that do not differ from their neighbours)
I = (diff(px)|diff(py));
px = px(I);
py = py(I);

end