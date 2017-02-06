function [radii,angles,center] = edit_AC_manual(image,center,radii,angles)
% [radii,angles,center] = edit_AC_manual(image,center,radii,angles)
% manually modify the outline of a cell by image interaction.
%
% image     -   image to show
% center    -   center of the cell (defaults to image center)
% radii     -   radial knots used to make the spline (defaults to 6 
%               evenly space radii of length 5)
% angles    -   the angles to which these radii correspond (defaults to 6
%               evenly space angles in the range [0,2pi] 
%
% shows an image and invites the user to click. When a user clicks the
% angle and distance from the center of the click is found and this
% distance assigned to the nearest angle in radii. The lines of these
% angles are also shown in the image, as is the cell outline.
%
% See also ACBACKGROUNDFUNCTIONS.GET_OUTLINE_FROM_RADII


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

cell_fig_handle = figure;
    
while true
    
    outline_im = ACBackGroundFunctions.get_outline_from_radii(radii,angles,center,size(image));
    
    imshow(OverlapGreyRed(image,outline_im,[],[],true),[]);
    
    
    hold on
    for i =1:length(radii);
        lines_h(i) =  plot([xmin(i) xmax(i)]+center(1),[ymin(i) ymax(i)]+center(2),'b');
    end
    
    center_h = plot(center(1),center(2),'ob');
    hold off
    
    in = ginput(1);
    
    if isempty(in)
        close(cell_fig_handle);
        break
    end
    
    radii =  ACBackGroundFunctions.edit_radii_from_point(in,center,radii,angles);
    
    
end


end