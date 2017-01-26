
function filt_feat=createImFilterSetCellTrapStackDIC(cCellSVM,image)
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
image=double(image);
n_filt=4;
nHough=2*2;
nHoughIm=0;
nBW=1;
nSym=4;
if isempty(cCellSVM.se)
    cCellSVM.se.se3=strel('disk',3);
    cCellSVM.se.se2=strel('disk',2);
    cCellSVM.se.se1=strel('disk',1);
end
 
se1=cCellSVM.se.se1;
se2=cCellSVM.se.se2;
se3=cCellSVM.se.se3;
 
 
if ~isfield(cCellSVM.se,'trap')||isempty(cCellSVM.se.trap)
     
    cCellSVM.se.trap.f1=fspecial('gaussian',cCellSVM.radiusSmall*1.5,5);
    cCellSVM.se.trap.f2=fspecial('gaussian',8,2);
     
    cCellSVM.se.trap.trapEdge=double(cCellSVM.cTrap.contour);
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
image = cat(3,image,minim,maxim);

%normalize over range
for slicei = size(image,3)-3:size(image,3)
    
    tempim = image(:,:,slicei);
    tempim=tempim*imScale/median(tempim(:));
    
    image(:,:,slicei)=tempim;
end
im=image;
 
filt_feat=zeros(size(im,1)*size(im,2),(size(im,3)*n_filt)*nHough + (nHoughIm+1)*(size(im,3)*n_filt)*nBW + size(im,3)*n_filt + nSym,'double');
filt_im=zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double');
filt_im2=zeros(size(im,1),size(im,2),(size(im,3)*n_filt*nHoughIm),'double');
 
% sigma=.5;
% h(:,:,1) = fspecial('gaussian', 6, sigma);
% h(:,:,2) = fspecial('gaussian', 6, 7*sigma);
% h(:,:,3) = fspecial('gaussian', 10, 75*sigma);
 
%% The general pixel based features
nHoodS=true(floor(cCellSVM.radiusSmall*1.5));
for i=1:size(im,3)
    im_slice=im(:,:,i);
%     filt_feat(:,(i-1)*n_filt+1)=im_slice(:);
%     filt_im(:,:,(i-1)*n_filt+1)=im_slice;
     
    temp_im=imfilter(im_slice,fspecial('gaussian',cCellSVM.radiusSmall,cCellSVM.radiusSmall/3),'replicate');
    filt_feat(:,(i-1)*n_filt+2)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+2)=temp_im;
     
%     temp_im=imfilter(im_slice,fspecial('log',5,2),'replicate');
%     filt_feat(:,(i-1)*n_filt+3)=temp_im(:);
%     filt_im(:,:,(i-1)*n_filt+3)=temp_im;
     


    temp_im=imfilter(im_slice,fspecial('log',floor(cCellSVM.radiusSmall*1.5),cCellSVM.radiusSmall/5),'replicate');
    filt_feat(:,(i-1)*n_filt+3)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+3)=temp_im;
    
    hy = fspecial('sobel'); hx = hy';
    Iy = imfilter(im_slice, hy, 'replicate');
    Ix = imfilter(im_slice, hx, 'replicate');
    grad_im = sqrt(Ix.^2 + Iy.^2);
    filt_feat(:,(i-1)*n_filt+1)=grad_im(:);
    filt_im(:,:,(i-1)*n_filt+1)=grad_im;

    temp_im=stdfilt(im_slice,nHoodS);
    filt_feat(:,(i-1)*n_filt+4)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+4)=temp_im;
%      
%     for index=1:size(h,3)
%         g(:,:,index)=imfilter(im_slice,h(:,:,index),'replicate');
%     end
%      
%     temp_index=4;
%     for index=1:size(h,3)-1
%         for index2=index+1:size(h,3)
%             temp_index=temp_index+1;
%             temp_im=g(:,:,index)-g(:,:,index2);
%             filt_feat(:,(i-1)*n_filt+temp_index)=temp_im(:);
%             filt_im(:,:,(i-1)*n_filt+temp_index)=temp_im;
%         end
%     end
end
% temp_index=(i-1)*n_filt+temp_index;
 temp_index=(i)*n_filt;

%% The circular hough filters based on the first image set
if ~isfield(cCellSVM.se,'fltr4accum')||isempty(cCellSVM.se.fltr4accum)
    fltr4accum = ones(5,5);
    fltr4accum(2:4,2:4) = 2;
    fltr4accum(3,3) = 6;
    fltr4accum = fltr4accum / sum(fltr4accum(:));
%     fltr4accum=imresize(fltr4accum,.9);
    cCellSVM.se.fltr4accum=fltr4accum;
end
fltr4accum=imresize(cCellSVM.se.fltr4accum,cCellSVM.radiusSmall/6);
fltr4accum2=imresize(cCellSVM.se.fltr4accum,cCellSVM.radiusSmall/2.5);

dogIm=[];
for i=1:size(filt_im,3)
    [grdx, grdy] = gradient(single(filt_im(:,:,i)));

    [accum] =  CircularHough_Grd(filt_im(:,:,i),grdx,grdy, [cCellSVM.radiusSmall floor((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.4)+cCellSVM.radiusSmall],max(max(filt_im(:,:,i)))*.01,6,fltr4accum);
    diffIm=accum.*trapG;
    temp_im=accum-diffIm;
    temp_im(cCellSVM.cTrap.trapOutline>0)=temp_im(cCellSVM.cTrap.trapOutline>0)/2;
    temp_index=temp_index+1;
    filt_im2(:,:,(i-1)*nHough+1)=temp_im;
    filt_feat(:,temp_index)=temp_im(:);
    
    accum = imfilter((accum),f1,'replicate');
    diffIm=accum.*trapG2;
    temp_im=accum-diffIm;  
    temp_im(cCellSVM.cTrap.trapOutline>0)=temp_im(cCellSVM.cTrap.trapOutline>0)/2;
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    
    [accum] =  CircularHough_Grd(filt_im(:,:,i),grdx,grdy, [ceil((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.4)+cCellSVM.radiusSmall cCellSVM.radiusLarge],max(max(filt_im(:,:,i)))*.01,11,fltr4accum2);
    temp_index=temp_index+1;
    diffIm=accum.*trapG;
    temp_im=accum-diffIm;
    temp_im(cCellSVM.cTrap.trapOutline>0)=temp_im(cCellSVM.cTrap.trapOutline>0)/2;
    filt_feat(:,temp_index)=temp_im(:);
    filt_im2(:,:,(i-1)*nHough+2)=temp_im;

    accum = imfilter((accum),f1,'replicate');
    diffIm=accum.*trapG2;
    temp_im=accum-diffIm;  
    temp_im(cCellSVM.cTrap.trapOutline>0)=temp_im(cCellSVM.cTrap.trapOutline>0)/2;
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    
%     for index=1:size(h,3)
%         dogIm(:,:,index)=imfilter(temp_im,h(:,:,index),'replicate');
%     end
%     temp_im=diff(dogIm,1,3);
%     temp_index=temp_index+1;
%     filt_feat(:,temp_index)=temp_im(:);
    
end
 
%% Filters based on thresholding and distance transforms of the previous filters
strelClose=strel('disk',floor(cCellSVM.radiusSmall-2)/2);
if strelClose<2
    strelClose=2;
end
% tpDilated=cCellSVM.cTrap.trapOutline;
tpDilated=imdilate(cCellSVM.cTrap.trapOutline,strelClose);
r=floor(size(filt_im,1)/2);
c=floor(size(filt_im,2)/2);

for i=1:size(filt_im,3)%+size(filt_im2,3)
    if i-1<size(filt_im,3)
        
        
%         if rem(i,n_filt)>3 || rem(i,n_filt)==0
%             es_im=stdfilt(filt_im(:,:,i),n);
%         else
            es_im=filt_im(:,:,i); 
%         end
%         es_im=es_im-min(es_im(:));
        es_im=es_im/max(es_im(:));
        thresh=.8*graythresh(es_im(round(r-r*2/3:r+r*2/3),round(c-c*2/3:c+c*2/3)));

        if thresh>.9
            thresh=.9;
        end
        
        temp_im=es_im>thresh;
        closeIm=imdilate(temp_im,strelClose);
%         imbw=closeIm-imerode(temp_im,se2);    
        imbw=closeIm;
    else
        es_im=filt_im2(:,:,i-size(filt_im,3));
        es_im=es_im-min(es_im(:));
%         thresh=mean(es_im(:))+1.5*std(es_im(:));
%         thresh=mean(es_im(tpDilated(:)))+.5*std(es_im(tpDilated(:)));
        thresh=.7*graythresh(es_im(tpDilated(:)));
        temp_im=es_im>thresh;
        imbw=temp_im;
        
    end
    b_edge=4;
    imbw(1:b_edge,:)=0;
    imbw(:,end-b_edge:end)=0;
    imbw(:,1:b_edge)=0;
    imbw(end-b_edge:end,:)=0;
%     im_fill=imfill(imbw,'holes');
    im_fill_notrap=imbw;
    im_fill_notrap(cCellSVM.cTrap.trapOutline)=0;
    
    temp_im=bwdist(~im_fill_notrap);
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    
end
 
%% Add additional features based on symmetry of the trap, and predicted location of the cells
%
mcol=floor(size(im,2)/2);
mrow=floor(size(im,1)/2);
 
temp_im=zeros(size(im,1),size(im,2));
temp_im(:,mcol)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
%
temp_im=zeros(size(im,1),size(im,2));
temp_im(mrow,:)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
 
temp_im=zeros(size(im,1),size(im,2));
temp_im(mrow,mcol)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
%
temp_im=zeros(size(im,1),size(im,2));
temp_im(:,1)=1;temp_im(:,end)=1;
temp_im(1,:)=1;temp_im(end,:)=1;
temp_im(cCellSVM.cTrap.trapOutline)=1;
temp_im=bwdist(temp_im);
temp_index=temp_index+1;
filt_feat(:,temp_index)=temp_im(:);
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
%%
function [accum, varargout] = CircularHough_Grd(img, grdx,grdy,radrange, varargin)
 
 
%%%%%%%% Arguments and parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Validation of arguments
if ndims(img) ~= 2 || ~isnumeric(img),
    error('CircularHough_Grd: ''img'' has to be 2 dimensional');
end
if ~all(size(img) >= 32),
    error('CircularHough_Grd: ''img'' has to be larger than 32-by-32');
end
 
if numel(radrange) ~= 2 || ~isnumeric(radrange),
    error(['CircularHough_Grd: ''radrange'' has to be ', ...
        'a two-element vector']);
end
prm_r_range = sort(max( [0,0;radrange(1),radrange(2)] ));
 
% Parameters (default values)
prm_grdthres = 10;
prm_fltrLM_R = 8;
prm_multirad = 0.5;
func_compu_cen = true;
func_compu_radii = true;
 
% Validation of arguments
vap_grdthres = 1;
if nargin > (1 + vap_grdthres),
    if isnumeric(varargin{vap_grdthres}) && ...
            varargin{vap_grdthres}(1) >= 0,
        prm_grdthres = varargin{vap_grdthres}(1);
    else
        error(['CircularHough_Grd: ''grdthres'' has to be ', ...
            'a non-negative number']);
    end
end
 
vap_fltr4LM = 2;    % filter for the search of local maxima
if nargin > (1 + vap_fltr4LM),
    if isnumeric(varargin{vap_fltr4LM}) && varargin{vap_fltr4LM}(1) >= 3,
        prm_fltrLM_R = varargin{vap_fltr4LM}(1);
    else
        error(['CircularHough_Grd: ''fltr4LM_R'' has to be ', ...
            'larger than or equal to 3']);
    end
end
%
% vap_multirad = 3;
% if nargin > (1 + vap_multirad),
%     if isnumeric(varargin{vap_multirad}) && ...
%         varargin{vap_multirad}(1) >= 0.1 && ...
%         varargin{vap_multirad}(1) <= 1,
%     prm_multirad = varargin{vap_multirad}(1);
%     else
%         error(['CircularHough_Grd: ''multirad'' has to be ', ...
%             'within the range [0.1, 1]']);
%     end
% end
 
vap_fltr4accum = 4; % filter for smoothing the accumulation array
% Default filter (5-by-5)
fltr4accum=varargin{end};
% fltr4accum = ones(5,5);
% fltr4accum(2:4,2:4) = 2;
% fltr4accum(3,3) = 6;
% fltr4accum = fltr4accum / sum(fltr4accum(:));
% fltr4accum=imresize(fltr4accum,.6);
 
 
func_compu_cen = ( nargout > 1 );
func_compu_radii = ( nargout > 2 );
 
% Reserved parameters
dbg_on = false;      % debug information
dbg_bfigno = 4;
if nargout > 3,  dbg_on = true;  end
 
 
%%%%%%%% Building accumulation array %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Convert the image to single if it is not of
% class float (single or single)
% img=single(img);
 
% Compute the gradient and the magnitude of gradient
% [grdx,grdy] = imgradientxy(img);

grdmag = sqrt(grdx.^2 + grdy.^2);
 
% Get the linear indices, as well as the subscripts, of the pixels
% whose gradient magnitudes are larger than the given threshold
% grdmasklin = find(grdmag > prm_grdthres);
[grdmask_IdxI, grdmask_IdxJ] = find(grdmag > prm_grdthres);
% ind2sub(size(grdmag), grdmasklin);
sgf=size(grdmag);
grdmasklin = (grdmask_IdxJ-1)*(sgf(1))+grdmask_IdxI;
 
rr_4linaccum = single( prm_r_range );
linaccum_dr = [ (-rr_4linaccum(2) + 0.5) : -rr_4linaccum(1) , ...
    (rr_4linaccum(1) + 0.5) : rr_4linaccum(2) ];
 
lin2accum_aJ = floor( ...
    single(grdx(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( single(grdmask_IdxJ)+0.5 , [1,length(linaccum_dr)] ) ...
    );
lin2accum_aI = floor( ...
    single(grdy(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( single(grdmask_IdxI)+0.5 , [1,length(linaccum_dr)] ) ...
    );
 
% Clip the votings that are out of the accumulation array
mask_valid_aJaI = ...
    (lin2accum_aJ > 0) & lin2accum_aJ < (size(grdmag,2) + 1) & ...
    lin2accum_aI > 0 & lin2accum_aI < (size(grdmag,1) + 1);
 
mask_valid_aJaI_reverse = ~ mask_valid_aJaI;
lin2accum_aJ = lin2accum_aJ .* mask_valid_aJaI + mask_valid_aJaI_reverse;
lin2accum_aI = lin2accum_aI .* mask_valid_aJaI + mask_valid_aJaI_reverse;
% clear mask_valid_aJaI_reverse;
 
% Linear indices (of the votings) into the accumulation array
% lin2accum = sub2ind( size(grdmag), lin2accum_aI, lin2accum_aJ );
% sgf=size(grdmag);
lin2accum = (lin2accum_aJ-1)*(sgf(1))+lin2accum_aI;
%  idx3 = da*[1; sgf(1)] - sgf(1);

lin2accum_size = size( lin2accum );
lin2accum = reshape( lin2accum, [numel(lin2accum),1] );
% clear lin2accum_aI lin2accum_aJ;
 
% Weights of the votings, currently using the gradient maginitudes
% but in fact any scheme can be used (application dependent)
weight4accum = ...
    repmat( single(grdmag(grdmasklin)) , [lin2accum_size(2),1] ) .* ...
    (mask_valid_aJaI(:));
% clear mask_valid_aJaI;
 
% Build the accumulation array using Matlab function 'accumarray'
accum = accumarray( (lin2accum) , weight4accum );
accum = [ accum ; zeros( numel(grdmag) - numel(accum) , 1 ) ];
accum = reshape( accum, size(grdmag) );
 
%%%%%%%% Locating local maxima in the accumulation array %%%%%%%%%%%%
% Smooth the accumulation array
accum = filter2( fltr4accum, accum );
