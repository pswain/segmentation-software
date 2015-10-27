%%

imin = ones(512,512);
minim = zeros(31,31);
half_minim_size = (size(minim)-1)/2;
centre = [61,216];
imout = ACBackGroundFunctions.put_cell_image(imin,minim,centre);

imtool(imout,[]);

if any(size(imout)~=size(imin))
    fprintf('fails on size')
end

[locy,locx] = find(imout==0);
if any(locx>(centre(1)+ half_minim_size(2)) | locx<(centre(1)- half_minim_size(2) ) | ...
        locy>(centre(2)+ half_minim_size(1)) | locy<(centre(1)- half_minim_size(1)))
    fprintf('fails on locaiton')
end
