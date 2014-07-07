function [image_out] = medfilt2nearest(image_in,filt_size)
%[image_out] = medfilt2nearest(image_in,filt_size) suppose to do median
%filter but replaced the padded values that are uncertain with the nearest
%values. Filter size must be odd in both dimensions

if any(mod(filt_size,2)==0)
    
    error('filt size must be odd in both dimensions')
    
end

edge_size = (filt_size-1)/2;

image_out = medfilt2(image_in,filt_size);

%bottom left

image_out((end + 1 - edge_size(1)):end,1:edge_size(2)) = image_out((end - edge_size(1)),edge_size(2) +1);

%top left

image_out(1:edge_size(1),1:edge_size(2)) = image_out(edge_size(1)+1,edge_size(2)+1);

%top right

image_out(1:edge_size(1),(end + 1 - edge_size(2)):end) = image_out(edge_size(1)+1,(end - edge_size(2)));

%bottom right

image_out((end + 1 - edge_size(1)):end,(end + 1 - edge_size(2)):end) = image_out((end - edge_size(1)),(end - edge_size(2)));


%top edge

image_out(1:edge_size(1),(edge_size(2)+1):(end-edge_size(2))) = ...
    repmat(image_out(edge_size(1)+1,(edge_size(2)+1):(end-edge_size(2))),edge_size(1),1);

%right edge

image_out((edge_size(1)+1):(end-edge_size(1)),(end +1 - edge_size(2)):end) = ...
    repmat(image_out((edge_size(1)+1):(end-edge_size(1)),end-edge_size(2)),1,edge_size(2));

%bottom edge

image_out((end +1 - edge_size(1)):end,(edge_size(2)+1):(end-edge_size(2))) =...
    repmat(image_out((end - edge_size(1)),(edge_size(2)+1):(end-edge_size(2))),edge_size(1),1);

%left edge

image_out((edge_size(1)+1):(end-edge_size(1)),1:edge_size(2)) = ...
    repmat(image_out((edge_size(1)+1):(end-edge_size(1)),edge_size(2)+1),1,edge_size(2));
end
