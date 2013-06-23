function [trapLocations trap_mask trapImages]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations,trapImagesPrevTp)

%% For each timepoint, identify the locations of the traps
%Go trhough each image in the timepoint object, and extract the locations
%of the traps using the identifyCellTrapsTimepoint function

%pass the trapLocations matrix from t-1 for the calculation of t cc. Uses the mask of
%the traps to increase the likelihood of finding the same trap again.

if nargin<5
    trapImagesPrevTp=[];
end


cTrap=cCellVision.cTrap;
% cTrap.trap1=imresize(cTrap.trap1,cCellVision.pixelSize/cTimelapse.pixelSize);
% cTrap.trap2=imresize(cTrap.trap2,cCellVision.pixelSize/cTimelapse.pixelSize);

% try
if isempty(cTimelapse.magnification)
    cTimelapse.magnification=60;
end


% catch
%     cTrap.trap1=imresize(cTrap.trap1,cCellVision.pixelSize/cTimelapse.pixelSize);
% cTrap.trap2=imresize(cTrap.trap2,cCellVision.pixelSize/cTimelapse.pixelSize);
% end

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

if nargin<4
    trapLocations=[];
end

image=cTimelapse.returnSingleTimepoint(timepoint);

if ~any(size(trapLocations))   
    trapLocations=predictTrapLocations(image,cTrap); 
end

% if isempty(trapImagesPrevTp)
    [trapLocations trap_mask trapImages]=updateTrapLocations(image,cTrap,trapLocations);
% else
% %     [trapLocations trap_mask trapImages]=updateTrapLocWithPrev(image,cTrap,trapLocations,trapImagesPrevTp);
% end

cTimelapse.cTimepoint(timepoint).trapLocations=trapLocations;

% cTimelapse.cTimepoint(timepoint).trapInfo=struct('segCenters',sparse(zeros(size(image))>0),'cell',struct('cellCenter',[],'cellRadius',[],'segmented',sparse(zeros(size(image))>0)), ...
%         'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0),'trackLabel',sparse(zeros(size(image))>0));
cTimelapse.cTimepoint(timepoint).trapInfo(1:length(trapLocations))=struct('segCenters',sparse(zeros(size(image))>0),'cell',struct('cellCenter',[],'cellRadius',[],'segmented',sparse(zeros(size(image))>0)), ...
        'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(image))>0),'trackLabel',sparse(zeros(size(image))>0));

j=length(trapLocations);
if j<length(cTimelapse.cTimepoint(timepoint).trapInfo)
    cTimelapse.cTimepoint(timepoint).trapInfo(j+1:end)=[];
end



end

function [trapLocations trap_mask]=predictTrapLocations(image,cTrap)
timepoint_im=double(image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));

cc=normxcorr2(cTrap.trap1,image_temp)+normxcorr2(cTrap.trap2,image_temp);

cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=ones(size(cc,1),size(cc,2))*median(cc(:));
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);

cc=cc_new;
cc=(imfilter(abs(cc),fspecial('disk',1)));
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);
[max_im_cc, imax] = max(cc(:));
max_cc=max_im_cc;
trap_index=1;
trap_mask=false(size(cc,1),size(cc,2));

while max_cc> .75*max_im_cc
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    cc(ypeak-cTrap.bb_height*1:ypeak+cTrap.bb_height*1,xpeak-cTrap.bb_width*1:xpeak+cTrap.bb_width*1)=0;
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




function [trapLocations trap_mask trapImages]=updateTrapLocations(image,cTrap,trapLocations)
timepoint_im=double(image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],'replicate');%median(timepoint_im(:)));

cc=abs(normxcorr2(cTrap.trap1,image_temp))+abs(normxcorr2(cTrap.trap2,image_temp));
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=zeros(size(cc));%*median(cc(:));
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
cc=cc_new;
% f1=fspecial('gaussian',4,.8);
f1=fspecial('disk',1);
cc=(imfilter((cc),f1));
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

% cc=imfilter(cc,fspecial('log'));
% figure(101);imshow(cc,[]);colormap(jet);

cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);
trap_mask=false(size(cc,1),size(cc,2));
trapImages=zeros([size(cTrap.trap1) length(trapLocations)] );

for i=1:length(trapLocations)

    xcurrent=trapLocations(i).xcenter+cTrap.bb_width;
    ycurrent=trapLocations(i).ycenter+cTrap.bb_height;
    
    temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
    
    [maxval maxloc]=max(temp_im(:));
    [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);
    
    xcenter=(xcurrent+xpeak-cTrap.bb_width/3-1);
    ycenter=(ycurrent+ypeak-cTrap.bb_height/3-1);

    trapLocations(i).xcenter=xcenter-cTrap.bb_width;
    trapLocations(i).ycenter=ycenter-cTrap.bb_height;
    trap_mask(round(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height),round(xcenter-cTrap.bb_width:xcenter+cTrap.bb_width))=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
    ycenter=round(ycenter);xcenter=round(xcenter);
    trapImages(:,:,i)=image_temp(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height,xcenter-cTrap.bb_width:xcenter+cTrap.bb_width);
end
trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

end



function [trapLocations trap_mask trapImages]=updateTrapLocWithPrev(image,cTrap,trapLocations,trapImPrevTp)
timepoint_im=double(image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
imagePad=padarray(timepoint_im,[2*cTrap.bb_height 2*cTrap.bb_width],median(timepoint_im(:)));

xBorder=cTrap.bb_width*1.5;
yBorder=cTrap.bb_height*1.5;

trapImages=zeros(size(trapImPrevTp));
f1=fspecial('gaussian',5,1);
for i=1:length(trapLocations)

    xcurrent=trapLocations(i).xcenter+2*cTrap.bb_width;
    ycurrent=trapLocations(i).ycenter+2*cTrap.bb_height;
    
    tempImage=imagePad(ycurrent-yBorder:ycurrent+yBorder,xcurrent-xBorder:xcurrent+xBorder);
    prevTpIm=trapImPrevTp(:,:,i);
%     cc=normxcorr2(prevTpIm,tempImage);
%     if max(cc(:))<.5
        cc=normxcorr2(cTrap.trap1,tempImage)+normxcorr2(cTrap.trap2,tempImage)+normxcorr2(prevTpIm,tempImage);
%     end

    cc=imfilter(abs(cc),f1);
%     figure(213);imshow(cc,[]);colormap(jet);
%         figure(214);imshow(normxcorr2(cTrap.trap1,tempImage)+normxcorr2(cTrap.trap2,tempImage),[]);colormap(jet);

%     waitforbuttonpress;
    %
%         temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
%     
%     [maxval maxloc]=max(temp_im(:));
%     [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);
%     
%     xcenter=round(xcurrent+xpeak-cTrap.bb_width/3-1);
%     ycenter=round(ycurrent+ypeak-cTrap.bb_height/3-1);
% 
%     trapLocations(i).xcenter=xcenter-cTrap.bb_width;
%     trapLocations(i).ycenter=ycenter-cTrap.bb_height;

    
    %
%     temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
    ccTemp=zeros(size(cc));
    xt=round(size(cc,2)/2);yt=round(size(cc,1)/2);
    yd=round(cTrap.bb_height/3);xd=round(cTrap.bb_width/3);
    ccTemp(yt-yd:yt+yd, xt-xd:xt+xd)=...
        cc(yt-yd:yt+yd, xt-xd:xt+xd);
    cc=ccTemp;
    
    [maxval maxloc]=max(cc(:));
    [ypeak, xpeak] = ind2sub(size(cc),maxloc(1));
    
    xcenter=trapLocations(i).xcenter+xpeak-xBorder-1;
    ycenter=trapLocations(i).ycenter+ypeak-yBorder-1;

    trapLocations(i).xcenter=xcenter-1*cTrap.bb_width;
    trapLocations(i).ycenter=ycenter-1*cTrap.bb_height;
%     trap_mask(round(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height),round(xcenter-cTrap.bb_width:xcenter+cTrap.bb_width))=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
xcurrent=trapLocations(i).xcenter+2*cTrap.bb_width;
    ycurrent=trapLocations(i).ycenter+2*cTrap.bb_height;
    
    tempImage=imagePad(ycurrent-cTrap.bb_height:ycurrent+cTrap.bb_height,xcurrent-cTrap.bb_width:xcurrent+cTrap.bb_width);
trapImages(:,:,i)=tempImage;
% trapImages(:,:,i)=imagePad(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height,xcenter-cTrap.bb_width:xcenter+cTrap.bb_width);
end
% trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
trap_mask=[];
end