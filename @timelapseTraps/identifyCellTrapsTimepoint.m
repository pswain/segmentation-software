function [cTrap cTrapPrior cc_withprior]=identifyCellTrapsTimepoint(cTimepoint,cTrap,cTrapPrior)
% this rotates every image to matchup with the trap, and then identifies
% the trap locations based on the idealized traps using the first (and
% second?) principle components of large numbers of traps. 

%requires the following
% timepoint_im - a single 2D DIC image of traps

% cTrap.image_rotation=angle the image needs to be rotated to correspond
% to the trap
%cTrap.thresh = threshold relative to the maximum cross-correlation that
%will be counted as a trap.
% cTrap.trap1= the first principle component trap
% cTrap.trap2= the second principle component trap
% cTrap.bb_height = the height of the bounding box for the trap
% cTrap.bb_width = the width of the boudning box for the trap

%it returns the following
% cTrap{trap_index}.image=the image of the trap
% cTrap{trap_index}.xcenter=the x-center of the trap in the larger image
% cTrap{trap_index}.ycenter=the y-center of the trap

% EDITORIAL: I don't think that it should return the trap image. That seems
% like a massive waste of time and memory, just point to the original image
% locations for the trap. Instead of rotating all images, why not just
% rotate the trap to matchup with the images.


timepoint_im=double(cTimepoint.image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
% timepoint_im=uint8(timepoint_im);
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));

cc=normxcorr2(cTrap.trap1,image_temp)+normxcorr2(cTrap.trap2,image_temp);
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=zeros(size(cc,1),size(cc,2));
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
% cc_new(cTrap.bb_height*1:end-cTrap.bb_height*1,cTrap.bb_width*1:end-cTrap.bb_width*1)=cc(cTrap.bb_height*1:end-cTrap.bb_height*1,cTrap.bb_width*1:end-cTrap.bb_width*1);

cc=cc_new;

cc=(imfilter(abs(cc),fspecial('disk',3)));
sigma=.1;
h(:,:,1) = fspecial('gaussian', 10, sigma);
h(:,:,2) = fspecial('gaussian', 10, 10*sigma);
for index=1:size(h,3)
    g(:,:,index)=imfilter(cc,h(:,:,index),'replicate');
end
temp_im=abs(g(:,:,1)-g(:,:,2));

cc=temp_im;;
cc_original=temp_im;
cTrapPrior.trap_mask=zeros(size(cc,1),size(cc,2));
for r=1:length(cTrapPrior.xcenter)
    cTrapPrior.trap_mask(cTrapPrior.ycenter(r)+cTrap.bb_height,cTrapPrior.xcenter(r)+cTrap.bb_width)=1;
end
stemp=strel('disk',12);
cTrapPrior.trap_mask=imdilate(cTrapPrior.trap_mask,stemp)>0;

if length(cTrapPrior.cc)
    cTrapPrior.cc=imdilate(cTrapPrior.cc,strel('disk',7));

    cc(cTrapPrior.trap_mask)=cTrap.Prior*(cTrapPrior.cc(cTrapPrior.trap_mask))+cc(cTrapPrior.trap_mask);

else
    cTrapPrior.cc=zeros(size(cc,1),size(cc,1));
end
cc_withprior=cc;

[max_im_cc, imax] = max(cc(:));
max_cc=max_im_cc;
trap_index=1;
cTrap.trap_mask=false(size(cc,1),size(cc,2));

while max_cc> cTrap.thresh*max(cc_original(:)) | trap_index<=cTrapPrior.num_traps
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    corr_offset = [ (ypeak+size(cTrap.trap1,1)/2) (xpeak+size(cTrap.trap1,2)/2) ];
    cc(ypeak-cTrap.bb_height*1:ypeak+cTrap.bb_height*1,xpeak-cTrap.bb_width*1:xpeak+cTrap.bb_width*1)=0;
    
    %     cTimepoint.trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=logical(ones(size(cTrap.trap1,1),size(cTrap.trap1,2)));
    %     cTrap(trap_index).image=image_temp(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width);
    xcenter=xpeak-cTrap.bb_width;
    ycenter=ypeak-cTrap.bb_height;
    cTrap.xcenter(trap_index)=xcenter;
    cTrap.ycenter(trap_index)=ycenter;
    cTrap.trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
%     figure(1);imshow(cc,[]);colormap(jet);pause(.5)
%     figure(2);imshow(cTimepoint.trap_mask,[]);pause(.5)
    trap_index=trap_index+1;   
    [max_cc, imax] = max(cc(:));

end
cTrapPrior.cc=cc_original;
cTrapPrior.num_traps=trap_index-1;
cTrap.trap_mask=cTrap.trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);