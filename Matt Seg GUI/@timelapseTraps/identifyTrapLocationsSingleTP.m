function [trapLocations trap_mask trapImages cc image]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp,trapLocationsToCheck,cc,im)
% [trapLocations, trap_mask, trapImages]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp,trapLocationsToCheck)
%
% function for identifying traps in the single timepoint using cross
% correlation and producing:
% trap_mask : a logical of all the areas defined as being parts of traps in
%             an image (note, ot the pillars, but the trap areas)
% trapImage : a stack of images of each trap.
%
% If trapLocations are provided then these images are simply generated
% using those locations.
%
% If trapLocations are not provided (i.e. in a call like:
%
%           cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision)
%
% the trap1 field of cCellVision.cTrap is cross correlated with the first
% channel of cTimelapse at timepoint 'timepoint' (note, the first channel
% is always used, so this should correspond to the image in trap1 of
% cCellVision). A normalised cross correlation is calculated, the absolute
% taken (I'm not sure why, probably beccause DIC is often somewhat
% variable), and local maxima chosen until all the points above a threhold
% (0.65* the maximum of the cross correlation) have been selected. At each
% new selection, the points in its immediate vicinity are rules out.
%
% If TrapLocationToCheck is the string 'none', it has no effect, if it is an
% index then those trapLocations are shifted to their nearest maxima in the
% cross correlation image. This is sort of a half way between the two
% behaviours used in trap selection. Most of the trap Locations are left
% unaffected, but only those in trapLocationsToCheck are changed.
%
% trapImagesPrevTp is no longer used, but don't want to remove it since it
% will mess up calls to the function.

if nargin<5 || isempty(trapImagesPrevTp)
    trapImagesPrevTp=[];
end

if nargin<6 || isempty(trapLocationsToCheck)
    trapLocationsToCheck='none'; %traps to put through the 'find nearest best point and set trap location to that' mill. if string 'none' does none of them.
end

if nargin<7 || isempty(cc)
    cc=[]; %just to avoid redoing the cc if not necessary
end

if nargin<8 || isempty(im)
    im=[]; %just to avoid redoing the cc if not necessary
end


cTrap=cCellVision.cTrap;

if isempty(cTimelapse.magnification)
    cTimelapse.magnification=60;
end

% put something here about magnification of you want so that everything is
% super consistent.
%
% cTrapSize should be cTrap with reverse magnification.
% then reverse magnify cTrap.cTrap1 to get trapImages.
% if you do this you need to change the editCellVisionTrapOutline code too.

cTrap.bb_width=ceil((size(cTrap.trap1,2)-1)/2);
cTrap.bb_height=ceil((size(cTrap.trap1,1)-1)/2);

d1=size(cTrap.trap1,1)-(cTrap.bb_height*2+1);
d2=size(cTrap.trap1,2)-(cTrap.bb_width*2+1);

if d1>0
    cTrap.trap1=padarray(cTrap.trap1,[d1 0],median(cTrap.trap1(:)),'post');
    cTrap.trap2=padarray(cTrap.trap2,[d1 0],median(cTrap.trap2(:)),'post');
end
if d2>0
    cTrap.trap1=padarray(cTrap.trap1,[0 d2],median(cTrap.trap1(:)),'post');
    cTrap.trap2=padarray(cTrap.trap2,[0 d2],median(cTrap.trap2(:)),'post');
end

cTimelapse.cTrapSize.bb_width=cTrap.bb_width;
cTimelapse.cTrapSize.bb_height=cTrap.bb_height;

if isempty(im)
    image=cTimelapse.returnSingleTimepoint(timepoint);
    image=double(image);
    image=image*cTrap.scaling/median(image(:));
    image=padarray(image,[cTrap.bb_height cTrap.bb_width],median(image(:)));

else
    image=im;
end

if nargin<4 || isempty(trapLocations)
    [trapLocations d cc]=predictTrapLocations(image,cTrap,[]); 
end

    [trapLocations trap_mask trapImages cc]=updateTrapLocations(image,cTrap,trapLocations,trapLocationsToCheck,cc);

cTimelapse.cTimepoint(timepoint).trapLocations=trapLocations;

trapInfo = cTimelapse.trapInfoTemplate;
trapInfo.segCenters = sparse(zeros(size(image))>0);
trapInfo.trackLabel = sparse(zeros(size(image))>0);
trapInfo.segmented =sparse(zeros(size(image))>0);
trapInfo.cell.segmented = sparse(zeros(size(image))>0);

cTimelapse.cTimepoint(timepoint).trapInfo=trapInfo ;
cTimelapse.cTimepoint(timepoint).trapInfo(1:length(trapLocations))= trapInfo;


j=length(trapLocations);
if j<length(cTimelapse.cTimepoint(timepoint).trapInfo)
    cTimelapse.cTimepoint(timepoint).trapInfo(j+1:end)=[];
end



end

function [trapLocations, trap_mask, ccCalc]=predictTrapLocations(image,cTrap,cc)
% [trapLocations trap_mask]=predictTrapLocations(image,cTrap)
%
% uses trap1 of cTrap (an image of the trap) to identify traps in the image
% by normalised cross correlation. Takes 0.65*the maximum of the cross
% correlation as a threshold and picks all values below this in order,
% ruling out the area directly around each new trap Location.

image_temp=image;% image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));


if isempty(cc)
    cc=abs(normxcorr2(cTrap.trap1,image_temp))+abs(normxcorr2(cTrap.trap2,image_temp));
    cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
    cc_new=zeros(size(cc));%*median(cc(:));
    cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
    cc=cc_new;
    % f1=fspecial('gaussian',4,.8);
    f1=fspecial('disk',1);
    cc=(imfilter((cc),f1));
    cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
    cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);

end
ccCalc=cc;


[max_im_cc, imax] = max(cc(:));
max_cc=max_im_cc;
trap_index=1;
trap_mask=false(size(cc,1),size(cc,2));

ccBounding=1.2;
while max_cc> .45*max_im_cc
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    bY=floor(cTrap.bb_height*ccBounding);
    bX=floor(cTrap.bb_width*ccBounding);
    cc(ypeak-bY:ypeak+bY,xpeak-bX:xpeak+bX)=0;
    xcenter=xpeak-cTrap.bb_width;
    ycenter=ypeak-cTrap.bb_height;
    trapLocations(trap_index).xcenter=xcenter;
    trapLocations(trap_index).ycenter=ycenter;
    trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
    trap_index=trap_index+1;
    [max_cc, imax] = max(cc(:));   
end
trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
end




function [trapLocations, trap_mask, trapImages, cc]=updateTrapLocations(image,cTrap,trapLocations,trapLocationsToCheck,cc)
% [trapLocations, trap_mask ,trapImages] = updateTrapLocations(image,cTrap,trapLocations,trapLocationsToCheck)
% 
% confusing function. I think its purpose is to make a trap_mask (a logical
% of all the trap pixels) and a trapImages stack (a stack of images of each
% trap) and also to take the index of any trap and move it to be at the
% closest local maxima of the cross correlation image. This is used in the
% addRemove traps function to put the final trap location at a local
% maxima in the vicinity of the point clicked.

if nargin<4 || isempty(trapLocationsToCheck)
    trapLocations = 1:length(trapLocationsToCheck);
elseif strcmp(trapLocationsToCheck,'none')
    trapLocationsToCheck = [];
end

image_temp=image;

if isempty(cc)
    cc=abs(normxcorr2(cTrap.trap1,image_temp))+abs(normxcorr2(cTrap.trap2,image_temp));
    cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
    cc_new=zeros(size(cc));%*median(cc(:));
    cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
    cc=cc_new;
    % f1=fspecial('gaussian',4,.8);
    f1=fspecial('disk',1);
    cc=(imfilter((cc),f1));
    cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
    cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);

end

trap_mask=false(size(cc,1),size(cc,2));
trapImages=zeros([size(cTrap.trap1) length(trapLocations)] );

for i=1:length(trapLocations)

    xcurrent=trapLocations(i).xcenter+cTrap.bb_width;
    ycurrent=trapLocations(i).ycenter+cTrap.bb_height;
    
    if ismember(i,trapLocationsToCheck) 
        %if this is one of the trap locations to check, make it's location
        %the maximum cross correlation value within a sixth of a trap width
        %of the point selected for the trap.
        temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));

        [maxval, maxloc]=max(temp_im(:));
        [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);

        xcenter=(xcurrent+xpeak-cTrap.bb_width/3-1);
        ycenter=(ycurrent+ypeak-cTrap.bb_height/3-1);

        trapLocations(i).xcenter=xcenter-cTrap.bb_width;
        trapLocations(i).ycenter=ycenter-cTrap.bb_height;
    else
        xcenter = trapLocations(i).xcenter + cTrap.bb_width;
        ycenter = trapLocations(i).ycenter + cTrap.bb_height;
    end
    trap_mask(round(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height),round(xcenter-cTrap.bb_width:xcenter+cTrap.bb_width))=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
    ycenter=round(ycenter);
    xcenter=round(xcenter);
    trapImages(:,:,i)=image_temp(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height,xcenter-cTrap.bb_width:xcenter+cTrap.bb_width);
end
trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

end



% NO LONGER USED AYWHERE
% 
% function [trapLocations trap_mask trapImages]=updateTrapLocWithPrev(image,cTrap,trapLocations,trapImPrevTp)
% timepoint_im=double(image);
% timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
% imagePad=padarray(timepoint_im,[2*cTrap.bb_height 2*cTrap.bb_width],median(timepoint_im(:)));
% 
% xBorder=cTrap.bb_width*1.5;
% yBorder=cTrap.bb_height*1.5;
% 
% trapImages=zeros(size(trapImPrevTp));
% f1=fspecial('gaussian',5,1);
% for i=1:length(trapLocations)
% 
%     xcurrent=trapLocations(i).xcenter+2*cTrap.bb_width;
%     ycurrent=trapLocations(i).ycenter+2*cTrap.bb_height;
%     
%     tempImage=imagePad(ycurrent-yBorder:ycurrent+yBorder,xcurrent-xBorder:xcurrent+xBorder);
%     prevTpIm=trapImPrevTp(:,:,i);
% %     cc=normxcorr2(prevTpIm,tempImage);
% %     if max(cc(:))<.5
%         cc=normxcorr2(cTrap.trap1,tempImage)+normxcorr2(cTrap.trap2,tempImage)+normxcorr2(prevTpIm,tempImage);
% %     end
% 
%     cc=imfilter(abs(cc),f1);
% %     figure(213);imshow(cc,[]);colormap(jet);
% %         figure(214);imshow(normxcorr2(cTrap.trap1,tempImage)+normxcorr2(cTrap.trap2,tempImage),[]);colormap(jet);
% 
% %     waitforbuttonpress;
%     %
% %         temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
% %     
% %     [maxval maxloc]=max(temp_im(:));
% %     [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);
% %     
% %     xcenter=round(xcurrent+xpeak-cTrap.bb_width/3-1);
% %     ycenter=round(ycurrent+ypeak-cTrap.bb_height/3-1);
% % 
% %     trapLocations(i).xcenter=xcenter-cTrap.bb_width;
% %     trapLocations(i).ycenter=ycenter-cTrap.bb_height;
% 
%     
%     %
% %     temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
%     ccTemp=zeros(size(cc));
%     xt=round(size(cc,2)/2);yt=round(size(cc,1)/2);
%     yd=round(cTrap.bb_height/3);xd=round(cTrap.bb_width/3);
%     ccTemp(yt-yd:yt+yd, xt-xd:xt+xd)=...
%         cc(yt-yd:yt+yd, xt-xd:xt+xd);
%     cc=ccTemp;
%     
%     [maxval maxloc]=max(cc(:));
%     [ypeak, xpeak] = ind2sub(size(cc),maxloc(1));
%     
%     xcenter=trapLocations(i).xcenter+xpeak-xBorder-1;
%     ycenter=trapLocations(i).ycenter+ypeak-yBorder-1;
% 
%     trapLocations(i).xcenter=xcenter-1*cTrap.bb_width;
%     trapLocations(i).ycenter=ycenter-1*cTrap.bb_height;
% %     trap_mask(round(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height),round(xcenter-cTrap.bb_width:xcenter+cTrap.bb_width))=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
% xcurrent=trapLocations(i).xcenter+2*cTrap.bb_width;
%     ycurrent=trapLocations(i).ycenter+2*cTrap.bb_height;
%     
%     tempImage=imagePad(ycurrent-cTrap.bb_height:ycurrent+cTrap.bb_height,xcurrent-cTrap.bb_width:xcurrent+cTrap.bb_width);
% trapImages(:,:,i)=tempImage;
% % trapImages(:,:,i)=imagePad(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height,xcenter-cTrap.bb_width:xcenter+cTrap.bb_width);
% end
% % trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
% trap_mask=[];
% end