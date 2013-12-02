function F = cost_from_image(im,coords_full,y_length)
%computes the cost function due to the image for a single set of coords.
%Any repeats in the coords do not need to be unique.

%im          - image
%coords_full - [x y] coords of proposed pixels
%y_length    - height of image

%eliminate repeated coords. works because repeated coords are always
%adjacent to each other. (Matt came up with it - he's so clever)
I = (diff(coords_full(:,1))|diff(coords_full(:,2)));

%sums pixel values
F = (sum(im(coords_full(I,2)+(y_length*(coords_full(I,1)-1)))))/sum(I,1);


end