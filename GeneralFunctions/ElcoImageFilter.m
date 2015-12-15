function [IMoutPOS,IMoutNEG] = ElcoImageFilter(IMin,RadRange,grd_thresh,do_neg,pixels_to_ignore,make_image_logical,use_canny)
% attempt to, like the radial gradient funciton, make an image that is high
% for white circles inside black circles.
% Radrange can be an nx2 vector where each row is a different rad range which is applied seperately. 
% do_neg  =  0 -both
%            1 -only positive
%           -1 - only negative


ispercentile = false;
if nargin<3 || isempty(grd_thresh)
    grd_thresh = 0;
    ispercentile = false;
elseif iscell(grd_thresh)
    ispercentile = true;
    grd_thresh = grd_thresh{1};
end

if nargin<4 || isempty(do_neg)
    
    do_neg = 0;
    
end

if nargin<5 || isempty(pixels_to_ignore)
    
    pixels_to_ignore = false(size(IMin));
    
end


if nargin<6 || isempty(make_image_logical)
    
    make_image_logical = false;
    
end

if nargin<6 || isempty(use_canny)
    
    use_canny = false;
    
end


image_length = ceil(max(RadRange(:,2)));

num_transforms = size(RadRange,1);

IMoutNEG = [];
IMoutPOS = [];

if do_neg >-1
    IMoutPOS = zeros([size(IMin) num_transforms]);
end

if do_neg <1
    IMoutNEG = zeros([size(IMin) num_transforms]);
end

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


Rinvert = R;
Rinvert(Rinvert~=0) = 1./Rinvert(Rinvert~=0);

RMatrix = repmat(Rinvert,[1,1,num_transforms]);


for i=1:num_transforms
    Rlogical = R>=RadRange(i,1) & R <=RadRange(i,2);
    Rtemp = Rinvert;
    Rtemp(~Rlogical) = 0;
    RMatrix(:,:,i) =  Rtemp;
end
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

if ~ make_image_logical
    grdxPOS = grdx;
    grdxPOS(grdxPOS<grd_thresh | pixels_to_ignore) = 0;
    
    grdxNEG = -grdx;
    grdxNEG(grdxNEG<grd_thresh | pixels_to_ignore) = 0;
    
    grdyPOS = grdy;
    grdyPOS(grdyPOS<grd_thresh | pixels_to_ignore) = 0;
    
    grdyNEG = -grdy;
    grdyNEG(grdyNEG<grd_thresh | pixels_to_ignore) = 0;
else
    grdxPOS = 1*(grdx>grd_thresh & ~pixels_to_ignore);
    
    grdxNEG = 1*(grdx<-grd_thresh & ~pixels_to_ignore);
    
    grdyPOS = 1*(grdy>grd_thresh & ~pixels_to_ignore);
    
    grdyNEG = 1*(grdy<-grd_thresh & ~pixels_to_ignore);
end

if use_canny
    
%     IMcanny = edge(IMin,'canny');
%     
%     grdxPOS = 1*(grdxPOS>0 & IMcanny);
%     
%     grdxNEG = 1*(grdxNEG>0 & IMcanny);
%     
%     grdyPOS = 1*(grdyPOS>0 & IMcanny);
%     
%     grdyNEG = 1*(grdyNEG>0 & IMcanny);
%     
    
%     grdxPOS = 1*bwmorph(grdxPOS>0,'thin',Inf);
%     
%     grdxNEG = 1*bwmorph(grdxNEG>0,'thin',Inf);
%     
%     grdyPOS = 1*bwmorph(grdyPOS>0,'thin',Inf);
%     
%     grdyNEG = 1*bwmorph(grdyNEG>0,'thin',Inf);
%     

    grdxPOS = 1*grdxPOS>0;
    
    grdxNEG = 1*grdxNEG>0;
    
    grdyPOS = 1*grdyPOS>0;
    
    grdyNEG = 1*grdyNEG>0;
    
end

% %highlights areas of black surrounded by areas of white
% IMoutPOS = conv2(grdxPOS,1*(LEFTangle & Rlogical),'same') + conv2(grdxNEG,1*(RIGHTangle & Rlogical),'same') +...
%               conv2(grdyPOS,1*(UPangle & Rlogical),'same') + conv2(grdyNEG,1*(DOWNangle & Rlogical),'same');
% 
% %highlights areas of white surrounded by areas of black
% IMoutNEG = conv2(grdxPOS,1*(RIGHTangle & Rlogical),'same') + conv2(grdxNEG,1*(LEFTangle & Rlogical),'same') +...
%               conv2(grdyPOS,1*(DOWNangle & Rlogical),'same') + conv2(grdyNEG,1*(UPangle & Rlogical),'same');
% 

%highlights areas of black surrounded by areas of white
for i=1:num_transforms
    if do_neg >-1
        IMoutPOS(:,:,i) = conv2(grdxPOS,(LEFTangle.*RMatrix(:,:,i)),'same') + conv2(grdxNEG,(RIGHTangle.*RMatrix(:,:,i)),'same') +...
            conv2(grdyPOS,(UPangle.*RMatrix(:,:,i)),'same') + conv2(grdyNEG,(DOWNangle.*RMatrix(:,:,i)),'same');
    end
    
    if do_neg <1
        %highlights areas of white surrounded by areas of black
        IMoutNEG(:,:,i) = conv2(grdxPOS,(RIGHTangle.*RMatrix(:,:,i)),'same') + conv2(grdxNEG,(LEFTangle.*RMatrix(:,:,i)),'same') +...
            conv2(grdyPOS,(DOWNangle.*RMatrix(:,:,i)),'same') + conv2(grdyNEG,(UPangle.*RMatrix(:,:,i)),'same');
        
    end
end
end