function filt_feat=createImFilterBFStackSlides(cCellSVM,image,trapOutline)
% filt_feat=createImFilterBFStackSlides(cCellSVM,image,trapOutline)
% 
% filter set created by Ivan and Nahuel for cell identification using upper and lower
% out of focus image from bright field images.
%
% performs no normalisation, and expects the image to have been globally
% normalised by the subtraction of the median and the division by the 
% differenc between the 2nd and 98th percentile. 
% cellVision.imageProcessingMethod = 'twostage_norm'
 
%% Normalize the image and traps
n_filt=14;

if isempty(cCellSVM.se)
    cCellSVM.se.se3=strel('disk',3);
    cCellSVM.se.se2=strel('disk',2);
    cCellSVM.se.se1=strel('disk',1);
end
 
se1=cCellSVM.se.se1;
se2=cCellSVM.se.se2;
se3=cCellSVM.se.se3;
 
trapLogicalInner = trapOutline==1;
trapLogicalBig = trapOutline>0;
trapLogicalBIG = imdilate(trapLogicalBig,strel('disk',1));

image=double(image);

% project images and add to image stack so that they get used in filter
% construction
if size(image,3)>1
    image = cat(3,image,image(:,:,1) - image(:,:,2));
end

% set large trap pixels to median to try and stop them influencing the
% outcome.
modified_image = image;
for slicei = 1:size(image,3)
    slice_im = image(:,:,slicei);
    slice_im(trapLogicalBig) = median(slice_im(:));
    modified_image(:,:,slicei) = slice_im;
end


filt_feat=zeros(size(modified_image,1)*size(modified_image,2),size(modified_image,3)*n_filt,'double');
%filt_feat=zeros(size(modified_image,1)*size(modified_image,2),size(modified_image,3)*n_filt,'double');


temp_index = 1;
%temp_index = temp_index+1;

% hough stuff
fltr4accum = ones(5,5);
fltr4accum(2:4,2:4) = 2;
fltr4accum(3,3) = 6;
fltr4accum = fltr4accum / sum(fltr4accum(:));
fltr4accum=imresize(fltr4accum,2);
f1=fspecial('disk',4);

%elco cicular filter stuff
rad_means = (cCellSVM.radiusSmall : cCellSVM.radiusLarge)';
rad_ranges = [rad_means-0.5 rad_means+0.5];


%% generate features
for i=1:size(modified_image,3)
    im_slice=modified_image(:,:,i);
        
    %% image itself
    filt_feat(:,temp_index)=im_slice(:);
    temp_index = temp_index+1;
    
    %% standard features
    n=true(7);
    temp_im=stdfilt(im_slice,n);
    filt_feat(:,temp_index)=temp_im(:);
    temp_index = temp_index+1;
     
    temp_im=imfilter(temp_im,fspecial('gaussian',8,2),'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index = temp_index+1;

    [fx, fy]=gradient(im_slice,2,2);
    grad_mag = sqrt(fx.^2+fy.^2);
    temp_im= grad_mag;
    temp_im=imfilter(temp_im,fspecial('disk',2));
    filt_feat(:,temp_index)=temp_im(:);
    temp_index = temp_index+1;
     
    
    %% hough on gradient magnitude
    [temp_im] =  CircularHough_Grd_mod(im_slice, [cCellSVM.radiusSmall cCellSVM.radiusLarge],max(grad_mag(:))*.01,6,fltr4accum,trapLogicalBig);
    
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = imfilter((temp_im),f1,'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    %% Elco Hough filter
    
    %[IMoutPOS,IMoutNEG] = ElcoImageFilter(IMin,RadRange,grd_thresh,do_neg,pixels_to_ignore,make_image_logical)
    [IMoutPOS,IMoutNEG] = ElcoImageFilter(im_slice,rad_ranges,0,0,trapLogicalBig,false);

    % IMoutPOS handling
    temp_im = sum(IMoutPOS,3);
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = imfilter((temp_im),f1,'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = max(IMoutPOS,[],3);
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = imfilter((temp_im),f1,'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    % IMoutNEG  handling
    temp_im = sum(IMoutNEG,3);
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = imfilter((temp_im),f1,'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = max(IMoutNEG,[],3);
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    temp_im = imfilter((temp_im),f1,'replicate');
    filt_feat(:,temp_index)=temp_im(:);
    temp_index=temp_index+1;
    
    %% Elco tube filter

end


 

function [accum, varargout] = CircularHough_Grd_mod(img, radrange, varargin)
% modification of original function to not calculate the gradient image
% again.
 
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
fltr4accum=varargin{3};

if nargin>5
    exclude_mask = varargin{4};
else
    exclude_mask = false(size(img));
end
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


% removed - now the gradient magnitude is given instead of image.
% Compute the gradient and the magnitude of gradient
if img_is_double,
    [grdx, grdy] = gradient(img);
else
    [grdx, grdy] = gradient(imgf);
end
grdmag = sqrt(grdx.^2 + grdy.^2);

%grdmag = img;
 
% Get the linear indices, as well as the subscripts, of the pixels
% whose gradient magnitudes are larger than the given threshold
% also exclude any pixels in the exclude_mask (trap pixels)
grdmasklin = find(grdmag > prm_grdthres & ~exclude_mask);
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

