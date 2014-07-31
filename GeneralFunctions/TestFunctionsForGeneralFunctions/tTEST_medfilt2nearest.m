%test medfilt2nearest

filt_size = [5 3];
area_size = [14 11];

A = rand(area_size);

B = medfilt2nearest(A,filt_size);

C = medfilt2(A,filt_size);

D = B;
D(C==B) = 0

%should be non zero at the edges - couldn't think of anything better than
%testing by eye.