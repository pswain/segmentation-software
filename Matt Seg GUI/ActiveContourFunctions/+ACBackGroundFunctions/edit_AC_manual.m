function [radii,angles,center] = edit_AC_manual(image,center,radii,angles)
%[radii,angles,center] = edit_AC_manual(image,center,radii,angles)
%manually provide the edge of the cells at time point one and
%use this for all downstream timepoints.





Rmin=2;
Rmax=max(size(image));

%assumes image has odd size
im_center =  round(fliplr(size(image) - 1)/2) +1;

if nargin<2 || isempty(center)
    
    center =  im_center;
    
end


if nargin<3 || isempty(radii)
    radii = 5*ones(6,1);
end


if nargin<4 || isempty(angles)
    
    angles = linspace(0,2*pi,(length(radii)+1))';
angles = angles(1:length(radii),1);
    
end

xmin = Rmin*cos(angles);
ymin = Rmin*sin(angles);

xmax = Rmax*cos(angles);
ymax = Rmax*sin(angles);

lines_h = zeros(size(xmin));

%get and px,py
[px,py] = ACBackGroundFunctions.get_points_from_radii(radii,angles,center,40,size(image));

%imshow(OverlayImage(dataobtainer_subfunction.get_small_cell_image(DICimage,center,offset),dataobtainer_subfunction.get_small_cell_image(GFPimage,center,offset)),[]);
cell_fig_handle = figure;
imshow(image,[]);


hold on
for i =1:length(radii);
    lines_h(i) =  plot([xmin(i) xmax(i)]+center(1),[ymin(i) ymax(i)]+center(2),'b');
end

center_h = plot(center(1),center(2),'ob');
plot_h = plot(px,py,'r');

in = ginput(1);

while ~isempty(in)
    
    
    radii =  ACBackGroundFunctions.edit_radii_from_point(in,center,radii,angles);
    
    [px,py] = ACBackGroundFunctions.get_points_from_radii(radii,angles,center,40,size(image));

    delete(plot_h);
    plot_h = plot(px,py,'r');
    
    in = ginput(1);
    
end

close(cell_fig_handle)
end