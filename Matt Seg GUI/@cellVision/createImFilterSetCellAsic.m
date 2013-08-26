function filt_feat=createImFilterSetCellAsic(cCellSVM,image)
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
image=image*1000/median(image(:));
im=image;
se2=strel('disk',1);
% filt_feat=zeros(size(im,1)*size(im,2),(size(im,3)*n_filt+size(HOGfeatures,3)),'single');
n_filt=5;
nHough=4*1;
nBW=1*1;
nSym=0;

filt_feat=zeros(size(im,1)*size(im,2),(1+nHough+nBW)*(size(im,3)*n_filt)+nSym,'double');
filt_im=zeros(size(im,1),size(im,2),(size(im,3)*n_filt),'double');
filt_im2=zeros(size(im,1),size(im,2),(size(im,3)*n_filt*nHough/2),'double');

sigma=.2;
h(:,:,1) = fspecial('gaussian', 10, sigma);
h(:,:,2) = fspecial('gaussian', 10, 10*sigma);
% h(:,:,3) = fspecial('gaussian', 15, 75*sigma);

%% The general pixel based features
for i=1:size(im,3)
    im_slice=im(:,:,i);
    
    n=true(5);
    temp_im=stdfilt(im_slice,n);
    filt_feat(:,(i-1)*n_filt+1)=temp_im(:);  
    filt_im(:,:,(i-1)*n_filt+1)=temp_im;

    stdGausIm=imfilter(temp_im,fspecial('gaussian',6,5),'replicate');
    temp_im=stdGausIm-max(stdGausIm(:))/2;
    temp_im=abs(temp_im);
    temp_im=temp_im/max(temp_im(:));
    temp_im=imcomplement(temp_im);
    filt_feat(:,(i-1)*n_filt+2)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+2)=temp_im;
    
    hy = fspecial('sobel'); hx = hy';
    Iy = imfilter(im_slice, hy, 'replicate');
    Ix = imfilter(im_slice, hx, 'replicate');
    grad_im = sqrt(Ix.^2 + Iy.^2);
    temp_im=grad_im;
%     temp_im=imfilter(grad_im,fspecial('gaussian',6,5),'replicate');
    filt_feat(:,(i-1)*n_filt+3)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+3)=temp_im;

    
    temp_im=imfilter(im_slice,fspecial('log',5,2),'replicate');
    filt_feat(:,(i-1)*n_filt+4)=temp_im(:);
    filt_im(:,:,(i-1)*n_filt+4)=temp_im;

    for index=1:size(h,3)
        g(:,:,index)=imfilter(im_slice,h(:,:,index),'replicate');
    end

    temp_index=4;
    for index=1:size(h,3)-1
        for index2=index+1:size(h,3)
            temp_index=temp_index+1;
            temp_im=g(:,:,index)-g(:,:,index2);
            filt_feat(:,(i-1)*n_filt+temp_index)=temp_im(:);
            filt_im(:,:,(i-1)*n_filt+temp_index)=temp_im;
        end
    end
end
temp_index=(i-1)*n_filt+temp_index;


%% The circular hough filters based on the first image set

% accum=zeros(size(im,1),size(im,2),size(filt_im,3));
for i=1:size(filt_im,3)
    [accum] =  CircularHough_Grd(filt_im(:,:,i), [cCellSVM.radiusSmall floor((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.7)+cCellSVM.radiusSmall],max(max(filt_im(:,:,i)))*.01,6);
    temp_im=accum;
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);

    temp_im=imfilter(accum,fspecial('gaussian',6,5),'replicate');
    temp_index=temp_index+1;
    filt_im2(:,:,(i-1)*nHough/2+1)=temp_im;
    filt_feat(:,temp_index)=temp_im(:);
    
    [accum] =  CircularHough_Grd(filt_im(:,:,i), [ceil((cCellSVM.radiusLarge-cCellSVM.radiusSmall)*.3)+cCellSVM.radiusSmall cCellSVM.radiusLarge],max(max(filt_im(:,:,i)))*.01,11);
    temp_im=accum;
    temp_index=temp_index+1;
    filt_feat(:,temp_index)=temp_im(:);
    
    temp_im=imfilter(accum,fspecial('gaussian',6,5),'replicate');
    temp_index=temp_index+1;
    filt_im2(:,:,(i-1)*nHough/2+2)=temp_im;
    filt_feat(:,temp_index)=temp_im(:);
end

%% Filters based on thresholding and distance transforms of the previous filters
n=true(5);
% filt_im=cat(3,filt_im ,filt_im2);
for i=1:(size(filt_im,3)+(size(filt_im2,3)))
    %         es_im(:,:,1)= entropyfilt(uint16(filt_im(:,:,i)),n);
    if i-1<size(filt_im,3)
        %             es_im(:,:,1)=stdfilt(filt_im(:,:,i),n);
        if i>n_filt-2
            es_im=stdfilt(filt_im(:,:,i),n);
        else
            es_im=filt_im(:,:,i);
        end  
    else
        es_im=filt_im2(:,:,i-size(filt_im,3));
    end
    % es_im=filt_im2(:,:,i);
%     es_im=es_im-min(es_im(:));
    es_im=es_im/max(es_im(:));

    for j=1:1
        temp_im=es_im(:,:,j);
%         if i~=2
            thresh=graythresh(temp_im)*1.3;
%         else
%             thresh=.8;
%         end
        if thresh>.9
            thresh=.9;
        end
        temp_im=im2bw(temp_im,thresh);
        imbw=imclose(temp_im,se2);
         
        b_edge=4;
        imbw(1:b_edge,:)=0;
        imbw(:,end-b_edge:end)=0;
        imbw(:,1:b_edge)=0;
        imbw(end-b_edge:end,:)=0;
        if i-1<size(filt_im,3)
            im_fill=imfill(imbw,'holes');
        else
            im_fill=imbw;
        end
        
im_fill_notrap=im_fill;
%         
%                 figure(1);imshow(imbw,[]);title(int2str(i));
% 
%         figure(2);imshow(im_fill,[]);title(int2str(i));pause(1);pause(1);
% % 
% %         
        temp_im=bwdist(~im_fill_notrap);
        temp_index=temp_index+1;
        filt_feat(:,temp_index)=temp_im(:);
%         
%         D=-temp_im;
%         D(temp_im<1) = -Inf;
%         imw=watershed(D);
%         
%         
%         bw_w=imw>1;
%         temp_im=bwdist(~bw_w);
%         
%                 
% 
%         temp_index=temp_index+1;
%         filt_feat(:,temp_index)=temp_im(:);        
    end
end































%%
function [accum, varargout] = CircularHough_Grd(img, radrange, varargin)
%Detect circular shapes in a grayscale image. Resolve their center
%positions and radii.
%
%  [accum, circen, cirrad, dbg_LMmask] = CircularHough_Grd(
%      img, radrange, grdthres, fltr4LM_R, multirad, fltr4accum)
%  Circular Hough transform based on the gradient field of an image.
%  NOTE:    Operates on grayscale images, NOT B/W bitmaps.
%           NO loops in the implementation of Circular Hough transform,
%               which means faster operation but at the same time larger
%               memory consumption.
%
%%%%%%%% INPUT: (img, radrange, grdthres, fltr4LM_R, multirad, fltr4accum)
%
%  img:         A 2-D grayscale image (NO B/W bitmap)
%
%  radrange:    The possible minimum and maximum radii of the circles
%               to be searched, in the format of
%               [minimum_radius , maximum_radius]  (unit: pixels)
%               **NOTE**:  A smaller range saves computational time and
%               memory.
%
%  grdthres:    (Optional, default is 10, must be non-negative)
%               The algorithm is based on the gradient field of the
%               input image. A thresholding on the gradient magnitude
%               is performed before the voting process of the Circular
%               Hough transform to remove the 'uniform intensity'
%               (sort-of) image background from the voting process.
%               In other words, pixels with gradient magnitudes smaller
%               than 'grdthres' are NOT considered in the computation.
%               **NOTE**:  The default parameter value is chosen for
%               images with a maximum intensity close to 255. For cases
%               with dramatically different maximum intensities, e.g.
%               10-bit bitmaps in stead of the assumed 8-bit, the default
%               value can NOT be used. A value of 4% to 10% of the maximum
%               intensity may work for general cases.
%
%  fltr4LM_R:   (Optional, default is 8, minimum is 3)
%               The radius of the filter used in the search of local
%               maxima in the accumulation array. To detect circles whose
%               shapes are less perfect, the radius of the filter needs
%               to be set larger.
%
% multirad:     (Optional, default is 0.5)
%               In case of concentric circles, multiple radii may be
%               detected corresponding to a single center position. This
%               argument sets the tolerance of picking up the likely
%               radii values. It ranges from 0.1 to 1, where 0.1
%               corresponds to the largest tolerance, meaning more radii
%               values will be detected, and 1 corresponds to the smallest
%               tolerance, in which case only the "principal" radius will
%               be picked up.
%
%  fltr4accum:  (Optional. A default filter will be used if not given)
%               Filter used to smooth the accumulation array. Depending
%               on the image and the parameter settings, the accumulation
%               array built has different noise level and noise pattern
%               (e.g. noise frequencies). The filter should be set to an
%               appropriately size such that it's able to suppress the
%               dominant noise frequency.
%
%%%%%%%% OUTPUT: [accum, circen, cirrad, dbg_LMmask]
%
%  accum:       The result accumulation array from the Circular Hough
%               transform. The accumulation array has the same dimension
%               as the input image.
%
%  circen:      (Optional)
%               Center positions of the circles detected. Is a N-by-2
%               matrix with each row contains the (x, y) positions
%               of a circle. For concentric circles (with the same center
%               position), say k of them, the same center position will
%               appear k times in the matrix.
%
%  cirrad:      (Optional)
%               Estimated radii of the circles detected. Is a N-by-1
%               column vector with a one-to-one correspondance to the
%               output 'circen'. A value 0 for the radius indicates a
%               failed detection of the circle's radius.
%
%  dbg_LMmask:  (Optional, for debugging purpose)
%               Mask from the search of local maxima in the accumulation
%               array.
%
%%%%%%%%% EXAMPLE #0:
%  rawimg = imread('TestImg_CHT_a2.bmp');
%  tic;
%  [accum, circen, cirrad] = CircularHough_Grd(rawimg, [15 60]);
%  toc;
%  figure(1); imagesc(accum); axis image;
%  title('Accumulation Array from Circular Hough Transform');
%  figure(2); imagesc(rawimg); colormap('gray'); axis image;
%  hold on;
%  plot(circen(:,1), circen(:,2), 'r+');
%  for k = 1 : size(circen, 1),
%      DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
%  end
%  hold off;
%  title(['Raw Image with Circles Detected ', ...
%      '(center positions and radii marked)']);
%  figure(3); surf(accum, 'EdgeColor', 'none'); axis ij;
%  title('3-D View of the Accumulation Array');
%
%  COMMENTS ON EXAMPLE #0:
%  Kind of an easy case to handle. To detect circles in the image whose
%  radii range from 15 to 60. Default values for arguments 'grdthres',
%  'fltr4LM_R', 'multirad' and 'fltr4accum' are used.
%
%%%%%%%%% EXAMPLE #1:
%  rawimg = imread('TestImg_CHT_a3.bmp');
%  tic;
%  [accum, circen, cirrad] = CircularHough_Grd(rawimg, [15 60], 10, 20);
%  toc;
%  figure(1); imagesc(accum); axis image;
%  title('Accumulation Array from Circular Hough Transform');
%  figure(2); imagesc(rawimg); colormap('gray'); axis image;
%  hold on;
%  plot(circen(:,1), circen(:,2), 'r+');
%  for k = 1 : size(circen, 1),
%      DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
%  end
%  hold off;
%  title(['Raw Image with Circles Detected ', ...
%      '(center positions and radii marked)']);
%  figure(3); surf(accum, 'EdgeColor', 'none'); axis ij;
%  title('3-D View of the Accumulation Array');
%
%  COMMENTS ON EXAMPLE #1:
%  The shapes in the raw image are not very good circles. As a result,
%  the profile of the peaks in the accumulation array are kind of
%  'stumpy', which can be seen clearly from the 3-D view of the
%  accumulation array. (As a comparison, please see the sharp peaks in
%  the accumulation array in example #0) To extract the peak positions
%  nicely, a value of 20 (default is 8) is used for argument 'fltr4LM_R',
%  which is the radius of the filter used in the search of peaks.
%
%%%%%%%%% EXAMPLE #2:
%  rawimg = imread('TestImg_CHT_b3.bmp');
%  fltr4img = [1 1 1 1 1; 1 2 2 2 1; 1 2 4 2 1; 1 2 2 2 1; 1 1 1 1 1];
%  fltr4img = fltr4img / sum(fltr4img(:));
%  imgfltrd = filter2( fltr4img , rawimg );
%  tic;
%  [accum, circen, cirrad] = CircularHough_Grd(imgfltrd, [15 80], 8, 10);
%  toc;
%  figure(1); imagesc(accum); axis image;
%  title('Accumulation Array from Circular Hough Transform');
%  figure(2); imagesc(rawimg); colormap('gray'); axis image;
%  hold on;
%  plot(circen(:,1), circen(:,2), 'r+');
%  for k = 1 : size(circen, 1),
%      DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
%  end
%  hold off;
%  title(['Raw Image with Circles Detected ', ...
%      '(center positions and radii marked)']);
%
%  COMMENTS ON EXAMPLE #2:
%  The circles in the raw image have small scale irregularities along
%  the edges, which could lead to an accumulation array that is bad for
%  local maxima detection. A 5-by-5 filter is used to smooth out the
%  small scale irregularities. A blurred image is actually good for the
%  algorithm implemented here which is based on the image's gradient
%  field.
%
%%%%%%%%% EXAMPLE #3:
%  rawimg = imread('TestImg_CHT_c3.bmp');
%  fltr4img = [1 1 1 1 1; 1 2 2 2 1; 1 2 4 2 1; 1 2 2 2 1; 1 1 1 1 1];
%  fltr4img = fltr4img / sum(fltr4img(:));
%  imgfltrd = filter2( fltr4img , rawimg );
%  tic;
%  [accum, circen, cirrad] = ...
%      CircularHough_Grd(imgfltrd, [15 105], 8, 10, 0.7);
%  toc;
%  figure(1); imagesc(accum); axis image;
%  figure(2); imagesc(rawimg); colormap('gray'); axis image;
%  hold on;
%  plot(circen(:,1), circen(:,2), 'r+');
%  for k = 1 : size(circen, 1),
%      DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
%  end
%  hold off;
%  title(['Raw Image with Circles Detected ', ...
%      '(center positions and radii marked)']);
%
%  COMMENTS ON EXAMPLE #3:
%  Similar to example #2, a filtering before circle detection works for
%  noisy image too. 'multirad' is set to 0.7 to eliminate the false
%  detections of the circles' radii.
%
%%%%%%%%% BUG REPORT:
%  This is a beta version. Please send your bug reports, comments and
%  suggestions to pengtao@glue.umd.edu . Thanks.
%
%
%%%%%%%%% INTERNAL PARAMETERS:
%  The INPUT arguments are just part of the parameters that are used by
%  the circle detection algorithm implemented here. Variables in the code
%  with a prefix 'prm_' in the name are the parameters that control the
%  judging criteria and the behavior of the algorithm. Default values for
%  these parameters can hardly work for all circumstances. Therefore, at
%  occasions, the values of these INTERNAL PARAMETERS (parameters that
%  are NOT exposed as input arguments) need to be fine-tuned to make
%  the circle detection work as expected.
%  The following example shows how changing an internal parameter could
%  influence the detection result.
%  1. Change the value of the internal parameter 'prm_LM_LoBndRa' to 0.4
%     (default is 0.2)
%  2. Run the following matlab code:
%     fltr4accum = [1 2 1; 2 6 2; 1 2 1];
%     fltr4accum = fltr4accum / sum(fltr4accum(:));
%     rawimg = imread('Frame_0_0022_portion.jpg');
%     tic;
%     [accum, circen] = CircularHough_Grd(rawimg, ...
%         [4 14], 10, 4, 0.5, fltr4accum);
%     toc;
%     figure(1); imagesc(accum); axis image;
%     title('Accumulation Array from Circular Hough Transform');
%     figure(2); imagesc(rawimg); colormap('gray'); axis image;
%     hold on; plot(circen(:,1), circen(:,2), 'r+'); hold off;
%     title('Raw Image with Circles Detected (center positions marked)');
%  3. See how different values of the parameter 'prm_LM_LoBndRa' could
%     influence the result.

%  Author:  Tao Peng
%           Department of Mechanical Engineering
%           University of Maryland, College Park, Maryland 20742, USA
%           pengtao@glue.umd.edu
%  Version: Beta        Revision: Mar. 07, 2007


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

vap_multirad = 3;
if nargin > (1 + vap_multirad),
    if isnumeric(varargin{vap_multirad}) && ...
        varargin{vap_multirad}(1) >= 0.1 && ...
        varargin{vap_multirad}(1) <= 1,
    prm_multirad = varargin{vap_multirad}(1);
    else
        error(['CircularHough_Grd: ''multirad'' has to be ', ...
            'within the range [0.1, 1]']);
    end
end

vap_fltr4accum = 4; % filter for smoothing the accumulation array
if nargin > (1 + vap_fltr4accum),
    if isnumeric(varargin{vap_fltr4accum}) && ...
            ndims(varargin{vap_fltr4accum}) == 2 && ...
            all(size(varargin{vap_fltr4accum}) >= 3),
        fltr4accum = varargin{vap_fltr4accum};
    else
        error(['CircularHough_Grd: ''fltr4accum'' has to be ', ...
            'a 2-D matrix with a minimum size of 3-by-3']);
    end
else
    % Default filter (5-by-5)
	fltr4accum = ones(5,5);
	fltr4accum(2:4,2:4) = 2;
	fltr4accum(3,3) = 6;
end

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

% Compute the linear indices (as well as the subscripts) of
% all the votings to the accumulation array.
% The Matlab function 'accumarray' accepts only double variable,
% so all indices are forced into double at this point.
% A row in matrix 'lin2accum_aJ' contains the J indices (into the
% accumulation array) of all the votings that are introduced by a
% same pixel in the image. Similarly with matrix 'lin2accum_aI'.
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


% Parameters to locate the local maxima in the accumulation array
% -- Segmentation of 'accum' before locating LM
prm_useaoi = true;
prm_aoithres_s = 2;
prm_aoiminsize = floor(min([ min(size(accum)) * 0.25, ...
    prm_r_range(2) * 1.5 ]));

% -- Filter for searching for local maxima
prm_fltrLM_s = 1.35;
prm_fltrLM_r = ceil( prm_fltrLM_R * 0.6 );
prm_fltrLM_npix = max([ 6, ceil((prm_fltrLM_R/2)^1.8) ]);

% -- Lower bound of the intensity of local maxima
prm_LM_LoBndRa = 0.2;  % minimum ratio of LM to the max of 'accum'

% Smooth the accumulation array
fltr4accum = fltr4accum / sum(fltr4accum(:));
accum = filter2( fltr4accum, accum );

