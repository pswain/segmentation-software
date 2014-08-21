function [IMoutPOS,IMoutNEG] = ElcoImageFilter(IMin,RadRange,grd_thresh)
%attempt to, like the radial gradient funciton, make an image that is high
%for white circles inside black circles.
ispercentile = false;
if nargin<3 || isempty(grd_thresh)
    grd_thresh = 0;
    ispercentile = false;
elseif iscell(grd_thresh)
    ispercentile = true;
    grd_thresh = grd_thresh{1};
end

image_length = RadRange(2);

xcoord = repmat(-image_length:image_length,(2*image_length +1),1);

ycoord = repmat((-image_length:image_length)',1,(2*image_length +1));

xcoord((image_length +1),(image_length +1)) = 1;

ycoord((image_length +1),(image_length +1)) = 1;

[R,angle] = ACBackGroundFunctions.xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,(2*image_length+1),(2*image_length+1));

angle = reshape(angle,(2*image_length+1),(2*image_length+1));


[grdx, grdy] = gradient(IMin);

if ispercentile
    
    grd_thresh = prctile([abs(grdx(:));abs(grdy(:))],grd_thresh);
    grd_thresh = grd_thresh(1);
    
end

Rlogical = R>=RadRange(1) & R <=RadRange(2);
Rinvert = R;
Rinvert(Rlogical) = 1./Rinvert(Rlogical);
Rinvert(~Rlogical) = 0;

%UPangle = angle<=(3/2 + 1/4) *pi & angle>=(3/2 - 1/4) *pi;
% 
% DOWNangle = angle<=(1/2 + 1/4) *pi & angle>=(1/2 - 1/4) *pi;
% 
% RIGHTangle = angle<=(1/4) *pi | angle>=(2 - 1/4) *pi;
% 
% LEFTangle = angle<=(1 + 1/4) *pi & angle>=(1 - 1/4) *pi;


UPangle = cos(angle - (3/2)*pi);
UPangle(UPangle<0) = 0;

DOWNangle = cos(angle - (1/2)*pi);
DOWNangle(DOWNangle<0) = 0;

LEFTangle = cos(angle - (1)*pi);
LEFTangle(LEFTangle<0) = 0;

RIGHTangle = cos(angle);
RIGHTangle(RIGHTangle<0) = 0;


grdxPOS = grdx;
grdxPOS(grdxPOS<grd_thresh) = 0;

grdxNEG = -grdx;
grdxNEG(grdxNEG<grd_thresh) = 0;

grdyPOS = grdy;
grdyPOS(grdyPOS<grd_thresh) = 0;

grdyNEG = -grdy;
grdyNEG(grdyNEG<grd_thresh) = 0;


% %highlights areas of black surrounded by areas of white
% IMoutPOS = conv2(grdxPOS,1*(LEFTangle & Rlogical),'same') + conv2(grdxNEG,1*(RIGHTangle & Rlogical),'same') +...
%               conv2(grdyPOS,1*(UPangle & Rlogical),'same') + conv2(grdyNEG,1*(DOWNangle & Rlogical),'same');
% 
% %highlights areas of white surrounded by areas of black
% IMoutNEG = conv2(grdxPOS,1*(RIGHTangle & Rlogical),'same') + conv2(grdxNEG,1*(LEFTangle & Rlogical),'same') +...
%               conv2(grdyPOS,1*(DOWNangle & Rlogical),'same') + conv2(grdyNEG,1*(UPangle & Rlogical),'same');
% 
%highlights areas of black surrounded by areas of white
IMoutPOS = conv2(grdxPOS,(LEFTangle.*Rinvert),'same') + conv2(grdxNEG,(RIGHTangle.*Rinvert),'same') +...
              conv2(grdyPOS,(UPangle.*Rinvert),'same') + conv2(grdyNEG,(DOWNangle.*Rinvert),'same');

%highlights areas of white surrounded by areas of black
IMoutNEG = conv2(grdxPOS,(RIGHTangle.*Rinvert),'same') + conv2(grdxNEG,(LEFTangle.*Rinvert),'same') +...
              conv2(grdyPOS,(DOWNangle.*Rinvert),'same') + conv2(grdyNEG,(UPangle.*Rinvert),'same');



end