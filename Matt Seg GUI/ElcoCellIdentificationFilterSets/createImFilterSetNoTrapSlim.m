function filt_feat=createImFilterSetNoTrapSlim(cCellSVM,image)
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
n_filt=2;
nHough=1;
nElco = 4; %number of Elco special transforms generated from each image.
           %currently 4 (2 normal, 2 smoothed versions of those)
if isempty(cCellSVM.se)
    cCellSVM.se.se3=strel('disk',3);
    cCellSVM.se.se2=strel('disk',2);
    cCellSVM.se.se1=strel('disk',1);
end
 
imScale=1000;
im=[];

image=double(image);
% 
% % project images and add to image stack so that they get used in filter
% % construction
% minim = min(image,[],3);
% maxim = max(image,[],3);
% image = cat(3,image,minim,maxim);
% 

Fgaussian82 =fspecial('gaussian',8,2);

for slicei = 1:size(image,3)
    
    temp_im = image(:,:,slicei);
    %attempt to remove broad changes in median from image by dividing by
    %local median
    %may be very slow - consider removing.
    %tempim = tempim./medfilt2nearest(tempim,[31 31]);
    temp_im = temp_im/median(temp_im(:));
    %temp_im=temp_im*imScale;
    temp_im = temp_im/(iqr(temp_im(:)));
    im(:,:,slicei)=temp_im;
    
end

im = cat(3,im,im(:,:,1)-im(:,:,end));
 
filt_feat=zeros(size(im,1)*size(im,2),size(im,3) + (size(im,3)*n_filt) + (size(im,3))*nHough  + nElco*size(im,3),'double');

%filt_im=cat(3,im,zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double'));
 

temp_index = 0; %iterates with each new filter added to the filter_feat
%% The general pixel based features
for i=1:size(im,3)
    im_slice=im(:,:,i);
     
    n=true(7);
    temp_im=stdfilt(im_slice,n);
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    %filt_im(:,:,size(im,3)+temp_index)=temp_im;
     
    temp_im=imfilter(temp_im,Fgaussian82,'replicate');
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    %filt_im(:,:,size(im,3)+temp_index)=temp_im;
end
%% The circular hough filters based on the first image set
fltr4accum = ones(5,5);
fltr4accum(2:4,2:4) = 2;
fltr4accum(3,3) = 6;
fltr4accum = fltr4accum / sum(fltr4accum(:));
fltr4accum=imresize(fltr4accum,2);
 

for i=1:size(im,3)

    [accum] =  CircularHough_Grd(im(:,:,i), [cCellSVM.radiusSmall cCellSVM.radiusLarge],max(max(im(:,:,i)))*.01,6,fltr4accum);
 
    temp_im=accum;
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
     
 
end
 

%% add images themselves to imfilt and smoothed versions

for i = 1:size(im,3)
    
    temp_index = temp_index+1;
    temp_im = im(:,:,i);
    filt_feat(:,temp_index) = temp_im(:);
    
    temp_index = temp_index+1;
    temp_im = imfilter(temp_im,Fgaussian82,'replicate');
    filt_feat(:,temp_index) = temp_im(:);
    
    
end

%% Elco's special transforms

%a collection of filters that work in a similar way to circular hough but
%try to be directional - so that the contributions of different gradients
%are applied separately.

elco_grd_thresh = 0;

for i = 1:size(im,3)
    
    [IMoutPOS,IMoutNEG] = ElcoImageFilter(im(:,:,i),[cCellSVM.radiusSmall cCellSVM.radiusLarge],elco_grd_thresh);
    
    temp_index = temp_index+1;
    filt_feat(:,temp_index) = IMoutPOS(:);
    
    temp_index = temp_index+1;
    temp_im=imfilter(IMoutPOS,Fgaussian82,'replicate');
    filt_feat(:,temp_index) = temp_im(:);
    
    temp_index = temp_index+1;
    filt_feat(:,temp_index) = IMoutNEG(:);
    
    temp_index = temp_index+1;
    temp_im=imfilter(IMoutNEG,Fgaussian82,'replicate');
    filt_feat(:,temp_index) = temp_im(:);
    
    
    
end
 
end

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
%%
function [accum, varargout] = CircularHough_Grd(img, radrange, varargin)
 
 
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
% class float (single or double)
img_is_double = isa(img, 'double');
if ~(img_is_double || isa(img, 'single')),
    imgf = single(img);
end
 
% Compute the gradient and the magnitude of gradient
if img_is_double,
    [grdx, grdy] = gradient(img);
else
    [grdx, grdy] = gradient(imgf);
end
grdmag = sqrt(grdx.^2 + grdy.^2);
 
% Get the linear indices, as well as the subscripts, of the pixels
% whose gradient magnitudes are larger than the given threshold
grdmasklin = find(grdmag > prm_grdthres);
[grdmask_IdxI, grdmask_IdxJ] = ind2sub(size(grdmag), grdmasklin);
 
rr_4linaccum = double( prm_r_range );
linaccum_dr = [ (-rr_4linaccum(2) + 0.5) : -rr_4linaccum(1) , ...
    (rr_4linaccum(1) + 0.5) : rr_4linaccum(2) ];
 
lin2accum_aJ = floor( ...
    double(grdx(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( double(grdmask_IdxJ)+0.5 , [1,length(linaccum_dr)] ) ...
    );
lin2accum_aI = floor( ...
    double(grdy(grdmasklin)./grdmag(grdmasklin)) * linaccum_dr + ...
    repmat( double(grdmask_IdxI)+0.5 , [1,length(linaccum_dr)] ) ...
    );
 
% Clip the votings that are out of the accumulation array
mask_valid_aJaI = ...
    lin2accum_aJ > 0 & lin2accum_aJ < (size(grdmag,2) + 1) & ...
    lin2accum_aI > 0 & lin2accum_aI < (size(grdmag,1) + 1);
 
mask_valid_aJaI_reverse = ~ mask_valid_aJaI;
lin2accum_aJ = lin2accum_aJ .* mask_valid_aJaI + mask_valid_aJaI_reverse;
lin2accum_aI = lin2accum_aI .* mask_valid_aJaI + mask_valid_aJaI_reverse;
clear mask_valid_aJaI_reverse;
 
% Linear indices (of the votings) into the accumulation array
lin2accum = sub2ind( size(grdmag), lin2accum_aI, lin2accum_aJ );
 
lin2accum_size = size( lin2accum );
lin2accum = reshape( lin2accum, [numel(lin2accum),1] );
clear lin2accum_aI lin2accum_aJ;
 
% Weights of the votings, currently using the gradient maginitudes
% but in fact any scheme can be used (application dependent)
weight4accum = ...
    repmat( double(grdmag(grdmasklin)) , [lin2accum_size(2),1] ) .* ...
    mask_valid_aJaI(:);
clear mask_valid_aJaI;
 
% Build the accumulation array using Matlab function 'accumarray'
accum = accumarray( lin2accum , weight4accum );
accum = [ accum ; zeros( numel(grdmag) - numel(accum) , 1 ) ];
accum = reshape( accum, size(grdmag) );
 
%%%%%%%% Locating local maxima in the accumulation array %%%%%%%%%%%%
% Smooth the accumulation array
accum = filter2( fltr4accum, accum );

end
