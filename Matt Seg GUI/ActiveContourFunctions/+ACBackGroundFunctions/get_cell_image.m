function show_image = get_cell_image(image,size_subimage,centerStack,m)
%function show_image = get_cell_image(image,center)

%get a stack of size_subimage by size_sub_image chunks of the image 
%centered on centers in the centre vector.
%size_subimage should be odd.
%centerStack = [x's  y's]

if numel(size_subimage) ==1
    size_subimage = [1 1] * size_subimage;
end

if nargin<4 || isempty(m)
    info = whos('image');
    if strcmp(info.class,'logical')
        m = false;
        show_image = false(size_subimage(1),size_subimage(2),size(centerStack,1));
    else
        m = median(image(:));
        show_image = zeros(size_subimage(1),size_subimage(2),size(centerStack,1));
    end
end

image = padarray(image,((size_subimage-1)/2),m);

 

%gets 30 by 30 square centered on 'center' in the original image
for i=1:size(centerStack,1)

    show_image(:,:,i) = image(round(centerStack(i,2))+(0:(size_subimage(1)-1))',round(centerStack(i,1))+(0:(size_subimage(2)-1))');

end

end