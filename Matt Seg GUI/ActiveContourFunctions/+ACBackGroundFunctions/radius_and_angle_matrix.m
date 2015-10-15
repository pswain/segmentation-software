function [R,angle] = radius_and_angle_matrix(matrix_size)
%[R,angle] = radius_and_angle_matrix(image_size) returns two matrices where containing the angle of
%and distance to each pixel from the centre of the image. image_size is just what would be returned
%by size(desired_matrix). (i.e [height width]).
%if both dimensions are odd the angle of the central pixel is changed from NaN to 0 for convenience.
image_length = floor(matrix_size/2);

if mod(matrix_size(1),2) == 1
    ycoord = repmat((-image_length(1):image_length(1))',1,matrix_size(2));
else
    ycoord = repmat([-image_length(1):-1 1:image_length(1)]',1,matrix_size(2));
end

if mod(matrix_size(2),2) == 1
    xcoord = repmat((-image_length(2):image_length(2)),matrix_size(1),1);
else
    xcoord = repmat([-image_length(2):-1 1:image_length(2)],matrix_size(1),1);
end

[R,angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,matrix_size);

angle = reshape(angle,matrix_size);

%if both odd set centreal square to 0 for convenience.
if mod(matrix_size(1),2) == 1 && mod(matrix_size(2),2) == 1
    angle(image_length(1)+1,image_length(2)+1) = 0;
end
    
end
