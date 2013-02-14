function identifyTrapLocations(cTimelapse,cCellVision,display,num_frames)

%% For each timepoint, identify the locations of the traps
%Go trhough each image in the timepoint object, and extract the locations
%of the traps using the identifyCellTrapsTimepoint function

%pass the cc matrix from t-1 for the calculation of t cc. Uses the mask of
%the traps to increase the likelihood of finding the same trap again.
cTrapPrior=cell(1)

cTrap=cCellVision.cTrap;
cTimelapse.cTrapSize.bb_width=cCellVision.cTrap.bb_width;
cTimelapse.cTrapSize.bb_height=cCellVision.cTrap.bb_height;

if nargin<4
    num_frames=length(cTimelapse.cTimepoint);
end

figure(1);fig1=gca;figure(2);fig2=gca;figure(3);fig3=gca;figure(4);fig4=gca;
for i=num_frames(1):num_frames(2)
    i

    timepoint_im=cTimelapse.returnSingleTimepoint(i);
    
%     if cCellVision.cTrap.objective==100
%         timepoint_im=imresize(timepoint_im,.6);
%     end
    
    if i>num_frames(1)
        tic
        [temp cTrapPrior ccwithprior]=identifyCellTrapsTimepoint(timepoint_im,cTrap,cTrapPrior);
        toc
%                 figure(4);imshow(ccwithprior,[]);colormap(jet);pause(.01)
%                 figure(5);imshow(cTrapPrior.trap_mask,[])
    else
        cTrapPrior.cc=[];
        cTrapPrior.xcenter=[];
        cTrapPrior.ycenter=[];
        cTrapPrior.num_traps=0;
        cTrapTemp=cTrap;
        cTrapTemp.thresh=cTrap.thresh_first;
        [ temp cTrapPrior ccwithprior]=identifyCellTrapsTimepoint(timepoint_im,cTrapTemp,cTrapPrior);
    end
    cTimelapse.cTimepoint(i).cTrap=temp;
    cTrapPrior.xcenter=temp.xcenter;
    cTrapPrior.ycenter=temp.ycenter;
    temp_im=timepoint_im;
    temp_im(cTimelapse.cTimepoint(i).cTrap.trap_mask)=1.5*timepoint_im(cTimelapse.cTimepoint(i).cTrap.trap_mask);
    
    if nargin>1
        switch display
            case 'all'
                imshow(cTrapPrior.cc,[],'Parent',fig1,'Colormap',colormap(jet));
                imshow(cTimelapse.returnSingleTimepoint(i),[],'Parent',fig2);
                imshow(temp_im,[],'Parent',fig3);pause(.01);
                imshow(ccwithprior,[],'Parent',fig4,'Colormap',colormap(jet));
            case 'cc'
                figure(1);imshow(cTrapPrior.cc,[]);colormap(jet);pause(.01)
            case 'images'
                figure(2);imshow(cTimelapse.returnSingleTimepoint(i),[]);title(['Timepoint ' int2str(i)]);pause(.01);
                figure(3);imshow(temp_im,[]);title(['Timepoint ' int2str(i)]);pause(.01);
        end
    end
end




function [cTrap cTrapPrior cc_withprior]=identifyCellTrapsTimepoint(timepoint_im,cTrap,cTrapPrior)
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

timepoint_im=double(timepoint_im);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
% timepoint_im=uint8(timepoint_im);
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));

% cc=normxcorr2(cTrap.trap1,image_temp);
cc=normxcorr2(cTrap.trap1,image_temp)+normxcorr2(cTrap.trap2,image_temp);

cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=ones(size(cc,1),size(cc,2))*median(cc(:));
% cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
% cc_new(cTrap.bb_height*1:end-cTrap.bb_height*1,cTrap.bb_width*1:end-cTrap.bb_width*1)=cc(cTrap.bb_height*1:end-cTrap.bb_height*1,cTrap.bb_width*1:end-cTrap.bb_width*1);
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5+2,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5+2)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5+2,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5+2);

cc=cc_new;
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
% figure(1);imshow(cc,[]);colormap(jet);
cc=(imfilter(abs(cc),fspecial('disk',1)));
% figure(2);imshow(cc,[]);colormap(jet);pause(.01);
sigma=.5;
h(:,:,1) = fspecial('gaussian', 12, sigma);
h(:,:,2) = fspecial('gaussian', 12, 50*sigma);
for index=1:size(h,3)
    g(:,:,index)=imfilter(cc,h(:,:,index),'replicate');
end
temp_im=abs(g(:,:,1)-g(:,:,2));
temp_im=cc;
cc=temp_im;
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


while max_cc> cTrap.thresh*max(cc_original(:)) | trap_index<cTrapPrior.num_traps

    
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    corr_offset = [ (ypeak+size(cTrap.trap1,1)/2) (xpeak+size(cTrap.trap1,2)/2) ];
    cc(ypeak-cTrap.bb_height*1:ypeak+cTrap.bb_height*1,xpeak-cTrap.bb_width*1:xpeak+cTrap.bb_width*1)=0;
    
    %     cTimepoint.trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=logical(ones(size(cTrap.trap1,1),size(cTrap.trap1,2)));
    %     cTrap(trap_index).image=image_temp(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width);
    xcenter=xpeak;
    ycenter=ypeak;
    cTrap.xcenter(trap_index)=xcenter;
    cTrap.ycenter(trap_index)=ycenter;
    cTrap.trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
%     figure(1);imshow(cc,[]);colormap(jet);pause(.5)
%     figure(2);imshow(cTimepoint.trap_mask,[]);pause(.5)
    trap_index=trap_index+1;   
    [max_cc, imax] = max(cc(:));

end
cTrapPrior.cc=cc_original;
cTrapPrior.num_traps=trap_index;
cTrap.trap_mask=cTrap.trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);