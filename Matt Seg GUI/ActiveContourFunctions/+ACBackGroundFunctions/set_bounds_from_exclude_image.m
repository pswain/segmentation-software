function [RminVec,RmaxVec] = set_bounds_from_exclude_image(exclude_logical,x,y,angles,RminVec,RmaxVec)
% [RminTP,RmaxTP] = set_bounds_from_exclude_image(exclude_logical,angles,RminVec,RmaxVec) set the
% upper and lower bounds on radial lines based on an exclude images which is a logical that is true
% at pixels that should not occur within the radial spline.
%
% assumes angles is ordered smallest to largest
% assumes all angles are written in the positive values. 
% assumes angles are positive and between 0 and 2pi

angles = reshape(angles,[],1);

[ycoord,xcoord] = find(exclude_logical);

xcoord = xcoord - x;
ycoord = ycoord -y;

I = xcoord==0 & ycoord==0;
ycoord(I) = [];
xcoord(I) = [];

[R,Angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

AngleDif = abs(repmat(Angle,1,length(angles)) - repmat(angles',length(Angle),1));

AngleDif(AngleDif>pi) = 2*pi - AngleDif(AngleDif>pi);

[~,closest_angle_point] = min(AngleDif,[],2);

for i=1:length(angles)
    
    RmaxVec(i) = min([R(closest_angle_point==i);RmaxVec(i)]);
    RminVec(i) = min(RminVec(i),RmaxVec(i));
    
end

end


