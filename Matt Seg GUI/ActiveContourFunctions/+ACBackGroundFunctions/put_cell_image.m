function receiving_image = put_cell_image(receiving_image,inserted_image,centerStack)
%function show_image = put_cell_image(receiving_image,inserted_image,centerStack)

%put a stack of inserted images into a receiving_image, going first to last, 
%centered on centers in the centre vector.
%inserted images should be od in the first two dimensions
%centerStack = [x's  y's]


size_subimage = [size(inserted_image,1) size(inserted_image,2)];

centerStack = double(centerStack);

receiving_image = padarray(receiving_image,((size_subimage-1)/2));

 

%gets 30 by 30 square centered on 'center' in the original image
for i=1:size(centerStack,1)
if size(inserted_image,3) == 1
    receiving_image(round(centerStack(i,2))+(0:(size_subimage(1)-1))',round(centerStack(i,1))+(0:(size_subimage(2)-1))') = inserted_image;
else
    receiving_image(round(centerStack(i,2))+(0:(size_subimage(1)-1))',round(centerStack(i,1))+(0:(size_subimage(2)-1))') = inserted_image(:,:,i);
end
end

receiving_image = receiving_image((1+(size_subimage(1)-1)/2):(end-(size_subimage(1)-1)/2),(1+(size_subimage(2)-1)/2):(end-(size_subimage(2)-1)/2));

end