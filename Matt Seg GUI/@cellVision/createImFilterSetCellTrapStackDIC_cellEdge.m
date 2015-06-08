
function filt_feat=createImFilterSetCellTrapStackDIC_cellEdge(cCellSVM,image)
% This function creates a set of image filters used for identifying the
% center of the cells located in the traps. It recieves a cropped image of
% the timepoint containing just the image of the trap. This image has
% the same dimensions as the cPCATrap. The cPCATrap is used to try to
% subtract the trap, and remove it from the image to improve image
% processing, and focus on the cells themselves.
 
% The raw image isn't used as a
 
% cPCATrap.pc_trap1= the first principle component trap
% cPCATrap.pc_trap2= the second principle component trap
 
%image= an image containing the trap and ideally some cells
 
%% Normalize the image and traps
n_filt=7;
nHough=0*1;
nHoughIm=0;
nBW=0;
nSym=0;
if isempty(cCellSVM.se)
    cCellSVM.se.se3=strel('disk',3);
    cCellSVM.se.se2=strel('disk',2);
    cCellSVM.se.se1=strel('disk',1);
end
 
se1=cCellSVM.se.se1;
se2=cCellSVM.se.se2;
se3=cCellSVM.se.se3;
 
 
if ~isfield(cCellSVM.se,'trap')||isempty(cCellSVM.se.trap)
     
    cCellSVM.se.trap.f1=fspecial('gaussian',8,5);
    cCellSVM.se.trap.f2=fspecial('gaussian',8,2);
     
    cCellSVM.se.trap.trapEdge=cCellSVM.cTrap.contour;
    cCellSVM.se.trap.trapEdge=imdilate(cCellSVM.se.trap.trapEdge,se1);   
    cCellSVM.se.trap.trapG=imfilter(cCellSVM.se.trap.trapEdge,cCellSVM.se.trap.f1);
    cCellSVM.se.trap.trapG=cCellSVM.se.trap.trapG/max(cCellSVM.se.trap.trapG(:));
    %     cCellSVM.se.trap.trapG2=imfilter(imdilate(cCellSVM.se.trap.trapEdge,se1),cCellSVM.se.trap.f2);
%     cCellSVM.se.trap.trapG2=cCellSVM.se.trap.trapG2/max(cCellSVM.se.trap.trapG2(:));
    cCellSVM.se.trap.trapG2=imfilter(double((cCellSVM.cTrap.trapOutline)),cCellSVM.se.trap.f2);
 
end
 
f1=cCellSVM.se.trap.f1;
f2=cCellSVM.se.trap.f2;
 
trapG=cCellSVM.se.trap.trapG;
trapG2=cCellSVM.se.trap.trapG2;
 
imScale=1000;
% im=[]; 
% image=double(image);
% image=image*imScale/median(image(:));
%  
% im(:,:,1)=image;
%  
% imageTemp=image-(image-imScale).*trapG;
% im(:,:,2)=imageTemp;
for slicei = 1:size(image,3)
    
    tempim = image(:,:,slicei);
    tempim=tempim*imScale/median(tempim(:));
    
    image(:,:,slicei)=tempim;
end


minim = min(image,[],3);
maxim = max(image,[],3);
rangeim=maxim-minim;
image = cat(3,image,minim,maxim,rangeim);

%normalize over range
im=[];
for slicei = 1:size(image,3)
    
    tempim = image(:,:,slicei);
    tempim=tempim*imScale/median(tempim(:));
    
    im(:,:,slicei)=tempim;
end
 
filt_feat=zeros(size(im,1)*size(im,2),(size(im,3)*n_filt)*nHough + (nHoughIm+1)*(size(im,3)*n_filt)*nBW + size(im,3)*n_filt + nSym,'double');
filt_im=zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double');

% filt_feat=zeros(size(im,1)*size(im,2),(size(im,3)*n_filt)*nHough + (nHoughIm+1)*(size(im,3)*n_filt)*nBW + size(im,3)*n_filt + nSym,'double');
% filt_im=zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double');
% filt_im2=zeros(size(im,1),size(im,2),(size(im,3)*n_filt*nHoughIm),'double');
 
sigma=.5;
h(:,:,1) = fspecial('gaussian', 6, sigma);
h(:,:,2) = fspecial('gaussian', 6, 7*sigma);
% h(:,:,3) = fspecial('gaussian', 10, 75*sigma);
 
%% The general pixel based features
for i=1:size(im,3)
    im_slice=im(:,:,i);
%      
%         im_slice=im(:,:,i);
%         filt_feat(:,(i-1)*n_filt+1)=temp_im(:);
% 
%     filt_im(:,:,(i-1)*n_filt+1)=temp_im;

    n=true(5);
    temp_im=stdfilt(im_slice,n);
    filt_feat(:,(i-1)*n_filt+1)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+1)=temp_im;
     
    temp_im=imfilter(temp_im,fspecial('gaussian',6,3),'replicate');
    filt_feat(:,(i-1)*n_filt+2)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+2)=temp_im;
     
    temp_im=imfilter(im_slice,fspecial('log',5,2),'replicate');
    filt_feat(:,(i-1)*n_filt+3)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+3)=temp_im;
    
    filt_feat(:,(i-1)*n_filt+4)=im_slice(:);
    filt_im(:,:,(i-1)*n_filt+4)=im_slice;
     


    temp_im=imfilter(im_slice,fspecial('laplacian'),'replicate');
    filt_feat(:,(i-1)*n_filt+5)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+5)=temp_im;
    
    temp_im=gradient(im_slice);
    filt_feat(:,(i-1)*n_filt+6)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+6)=temp_im;
     
    for index=1:size(h,3)
        g(:,:,index)=imfilter(im_slice,h(:,:,index),'replicate');
    end
     
    temp_index=5;
    for index=1:size(h,3)-1
        for index2=index+1:size(h,3)
            temp_index=temp_index+1;
            temp_im=g(:,:,index)-g(:,:,index2);
            filt_feat(:,(i-1)*n_filt+temp_index)=temp_im(:);
            filt_im(:,:,(i-1)*n_filt+temp_index)=temp_im;
        end
    end
end
% temp_index=(i-1)*n_filt+temp_index;
 temp_index=(i)*n_filt;
