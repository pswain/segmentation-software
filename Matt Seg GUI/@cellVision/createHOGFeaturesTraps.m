function [block cell]=createHOGFeaturesTraps(cCellSVM,image)
% cPatchParameters.bin=8;
% cPatchParameters.step_size_rows=4;
% cPatchParameters.step_size_cols=4;
% cPatchParameters.block_size_row=2;
% cPatchParameters.block_size_col=2;
% cPatchParameters.angle=180;
% cPatchParameters.DOGsigma=[.2 5];
% cPatchParameters.hsize=5;
% cPatchParameters.se = strel('disk',4);
% cPatchParameters.dog_bin=10;
% cPatchParameters.dog_max=1e4;
% cPatchParameters.se_syn=strel('disk',3);
% cPatchParameters.se_cell=strel('disk',9);
% cPatchParameters.num_neg=200;
% cPatchParameters.Gradbins=10;
% cPatchParameters.GradMax=2e3;
% cPatchParameters.backgroundse = strel('disk',5);

cPatchParameters=cCellSVM.cPatchParameters;
im=double(image.im);
im=im*1000/median(im(:));


bin=cPatchParameters.bin;
step_size_cols=cPatchParameters.step_size_cols;
step_size_rows=cPatchParameters.step_size_rows;

block_size_row=cPatchParameters.block_size_row;
block_size_col=cPatchParameters.block_size_col;
dog_bin=cPatchParameters.dog_bin;
dog_max=cPatchParameters.dog_max;

% [GradientX,GradientY] = gradient(double(image.im));
f=[-1 0 1];
im_med=medfilt2(im);
GradientX=imfilter(im_med,f,'replicate','same');
GradientY=imfilter(im_med,f','replicate','same');
GradientX(cCellSVM.cTrap.trapOutline>0)=median(GradientX(:));
GradientY(cCellSVM.cTrap.trapOutline>0)=median(GradientY(:));

Gr = sqrt((GradientX.*GradientX)+(GradientY.*GradientY));
GradientX(GradientX == 0) = 1e-6;

if cPatchParameters.angle==180
    YX = GradientY./GradientX;
    Angles = (atan(YX))+(pi/2);
    bins=0:pi/bin:pi;
else
    %below for -pi to pi
    Angles = atan2(GradientY,GradientX);
    bins=-pi:2*pi/bin:pi;
end
% bins=bins(1:end-1);

gauss_im=[];
%Make the DOG matrices
for i=1:length(cPatchParameters.DOGsigma)
    h1 = fspecial('gaussian', cPatchParameters.hsize, cPatchParameters.DOGsigma(i));
    gauss_im(:,:,i)=imfilter(image.im,h1,'replicate');
end
index=1;
dog_im=[];
for i=1:size(gauss_im,3)-1
    for j=i+1:size(gauss_im,3)
        dog_im(:,:,index)=abs(gauss_im(:,:,i)-gauss_im(:,:,j));
        index=index+1;
    end
end
   
cell=[];
log_im=abs(imfilter(im,fspecial('log',3),'replicate'));


% Filters based on thresholding and distance transforms of the previous filters
n=true(5);
std_im=stdfilt(im,n);
temp_im=std_im-min(std_im(:));
temp_im=temp_im/max(temp_im(:));
imbw=im2bw(temp_im,graythresh(temp_im)/2);
b_edge=5;
imbw=imclose(imbw,cCellSVM.cTrap.se3);

imbw(1:b_edge,1)=0;
imbw(:,end-b_edge:end)=0;
imbw(1:b_edge,:)=0;
imbw(end-b_edge:end,:)=0;
im_fill=imfill(imbw,'holes');
im_fill_notrap=im_fill;
im_fill_notrap(cCellSVM.cTrap.trapOutline)=0;
bwcells=bwdist(~im_fill_notrap);


[accum_im1, circen, cirrad] =  CircularHough_Grd(im, [cCellSVM.radiusSmall cCellSVM.radiusLarge],max(im(:))*.05,4,1);
accum_im1(cCellSVM.cTrap.trapOutline>0)=0;

[accum_im2, circen, cirrad] =  CircularHough_Grd(std_im, [cCellSVM.radiusSmall cCellSVM.radiusLarge],max(std_im(:))*.05,4,1);
accum_im2(cCellSVM.cTrap.trapOutline>0)=0;


Gr_pad=padarray(Gr,[step_size_rows step_size_cols],'post');
Angles_pad=padarray(Angles,[step_size_rows step_size_cols],'post');
dog_pad=padarray(dog_im,[step_size_rows step_size_cols],'post');
gray_pad=padarray(im,[step_size_rows step_size_cols],'post');
log_pad=padarray(log_im,[step_size_rows step_size_cols],'post');
accum1_pad=padarray(accum_im1,[step_size_rows step_size_cols],'post');
accum2_pad=padarray(accum_im2,[step_size_rows step_size_cols],'post');
bwcells_pad=padarray(bwcells,[step_size_rows step_size_cols],'post');
class_pad=padarray(image.class,[step_size_rows step_size_cols],'post');

for i=1:step_size_rows:size(Gr,1)
    for j=1:step_size_cols:size(Gr,2)
        gradient_temp=Gr_pad(i:i+step_size_rows,j:j+step_size_cols);
        Angles_temp=Angles_pad(i:i+step_size_rows,j:j+step_size_cols);
        dog_temp=dog_pad(i:i+step_size_rows,j:j+step_size_cols,:);
        gray_temp=gray_pad(i:i+step_size_rows,j:j+step_size_cols);
        log_temp=log_pad(i:i+step_size_rows,j:j+step_size_cols);
        accum1_temp=accum1_pad(i:i+step_size_rows,j:j+step_size_cols);
        accum2_temp=accum2_pad(i:i+step_size_rows,j:j+step_size_cols);
        bwcells_temp=bwcells_pad(i:i+step_size_rows,j:j+step_size_cols);

        
        [t, xout]=histc(Angles_temp(:),bins);
        for k=1:length(bins)-1
            cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,k)=sum(gradient_temp(xout==k));
        end
        
        dog_index=1;
        dog_bins=0:dog_max/dog_bin:dog_max;
        t=histc(dog_temp(:),dog_bins);
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,length(bins):length(bins)+length(t)-1)=t;
        cell_index=length(bins)+length(t);
%         
%         grad_bins=0:cPatchParameters.GradMax/cPatchParameters.Gradbins:cPatchParameters.GradMax;
%         t=histc(gradient_temp(:),grad_bins);
%         cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
%         cell_index=cell_index+length(t);
        
        t=[min(dog_temp(:)) max(dog_temp(:)) mean(dog_temp(:)) median(dog_temp(:)) std(dog_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(log_temp(:)) max(log_temp(:)) mean(log_temp(:)) median(log_temp(:)) std(log_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(gray_temp(:)) max(gray_temp(:)) mean(gray_temp(:)) median(gray_temp(:)) std(gray_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(gradient_temp(:)) max(gradient_temp(:)) mean(gradient_temp(:)) median(gradient_temp(:)) std(gradient_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);

        t=[min(Angles_temp(:)) max(Angles_temp(:)) mean(Angles_temp(:)) median(Angles_temp(:)) std(Angles_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(accum1_temp(:)) max(accum1_temp(:)) mean(accum1_temp(:)) median(accum1_temp(:)) std(accum1_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(accum2_temp(:)) max(accum2_temp(:)) mean(accum2_temp(:)) median(accum2_temp(:)) std(accum2_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
        
        t=[min(bwcells_temp(:)) max(bwcells_temp(:)) mean(bwcells_temp(:)) median(bwcells_temp(:)) std(bwcells_temp(:))];
        cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,cell_index:cell_index+length(t)-1)=t;
        cell_index=cell_index+length(t);
     
        cell_class(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1)=max(max(class_pad(i:i+step_size_rows,j:j+step_size_cols)));
       
     
    end
end

% %below is necessary when using the dualview b/c there will be lots of zeros
% %around the edge ofthe screen that will mess things up from the alignment
% bw_im=im==0;
% se=strel('disk',5);
% bw_im=imdilate(bw_im,se);
% bw_im=padarray(bw_im,[step_size_rows step_size_cols],'post');
% for i=1:step_size_rows:size(Gr,1)
%     for j=1:step_size_cols:size(Gr,2)
%         if max(max(bw_im(i:i+step_size_rows,j:j+step_size_cols)))==1
%             cell(floor(i/step_size_rows)+1,floor(j/step_size_cols)+1,:)=0;
%         end
%     end
% end
% 

cell=padarray(cell,[block_size_row block_size_col]);
cell_class=padarray(cell_class,[block_size_row block_size_col]);
block.output=zeros((size(cell,1)-2*block_size_row)*(size(cell,2)-2*block_size_col),(2*block_size_row+1)*(2*block_size_col+1)*size(cell,3))-100;
for i=block_size_row+1:size(cell,1)-block_size_row
    for j=block_size_col+1:size(cell,2)-block_size_col
        temp=cell(i-block_size_row:i+block_size_row,j-block_size_col:j+block_size_col,:);
        block.output((i-1-block_size_row)*(size(cell,2)-2*block_size_col)+(j-block_size_col),:)=reshape(temp, 1, (2*block_size_row+1)*(2*block_size_col+1)*size(cell,3));
        block.class ((i-1-block_size_row)*(size(cell,2)-2*block_size_col)+(j-block_size_col))=cell_class(i,j);
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

% Stop if no need to locate the center positions of circles
if ~func_compu_cen,
    return;
end
clear lin2accum weight4accum;

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

% Select a number of Areas-Of-Interest from the accumulation array
if prm_useaoi,
    % Threshold value for 'accum'
    prm_llm_thres1 = prm_grdthres * prm_aoithres_s;

    % Thresholding over the accumulation array
    accummask = ( accum > prm_llm_thres1 );

    % Segmentation over the mask
    [accumlabel, accum_nRgn] = bwlabel( accummask, 8 );

    % Select AOIs from segmented regions
    accumAOI = ones(0,4);
    for k = 1 : accum_nRgn,
        accumrgn_lin = find( accumlabel == k );
        [accumrgn_IdxI, accumrgn_IdxJ] = ...
            ind2sub( size(accumlabel), accumrgn_lin );
        rgn_top = min( accumrgn_IdxI );
        rgn_bottom = max( accumrgn_IdxI );
        rgn_left = min( accumrgn_IdxJ );
        rgn_right = max( accumrgn_IdxJ );        
        % The AOIs selected must satisfy a minimum size
        if ( (rgn_right - rgn_left + 1) >= prm_aoiminsize && ...
                (rgn_bottom - rgn_top + 1) >= prm_aoiminsize ),
            accumAOI = [ accumAOI; ...
                rgn_top, rgn_bottom, rgn_left, rgn_right ];
        end
    end
else
    % Whole accumulation array as the one AOI
    accumAOI = [1, size(accum,1), 1, size(accum,2)];
end

% Thresholding of 'accum' by a lower bound
prm_LM_LoBnd = max(accum(:)) * prm_LM_LoBndRa;

% Build the filter for searching for local maxima
fltr4LM = zeros(2 * prm_fltrLM_R + 1);

[mesh4fLM_x, mesh4fLM_y] = meshgrid(-prm_fltrLM_R : prm_fltrLM_R);
mesh4fLM_r = sqrt( mesh4fLM_x.^2 + mesh4fLM_y.^2 );
fltr4LM_mask = ...
	( mesh4fLM_r > prm_fltrLM_r & mesh4fLM_r <= prm_fltrLM_R );
fltr4LM = fltr4LM - ...
	fltr4LM_mask * (prm_fltrLM_s / sum(fltr4LM_mask(:)));

if prm_fltrLM_R >= 4,
	fltr4LM_mask = ( mesh4fLM_r < (prm_fltrLM_r - 1) );
else
	fltr4LM_mask = ( mesh4fLM_r < prm_fltrLM_r );
end
fltr4LM = fltr4LM + fltr4LM_mask / sum(fltr4LM_mask(:));

% **** Debug code (begin)
if dbg_on,
    dbg_LMmask = zeros(size(accum));
end
% **** Debug code (end)

% For each of the AOIs selected, locate the local maxima
circen = zeros(0,2);
for k = 1 : size(accumAOI, 1),
    aoi = accumAOI(k,:);    % just for referencing convenience
    
    % Thresholding of 'accum' by a lower bound
    accumaoi_LBMask = ...
        ( accum(aoi(1):aoi(2), aoi(3):aoi(4)) > prm_LM_LoBnd );
    
    % Apply the local maxima filter
    candLM = conv2( accum(aoi(1):aoi(2), aoi(3):aoi(4)) , ...
        fltr4LM , 'same' );
    candLM_mask = ( candLM > 0 );
    
    % Clear the margins of 'candLM_mask'
    candLM_mask([1:prm_fltrLM_R, (end-prm_fltrLM_R+1):end], :) = 0;
    candLM_mask(:, [1:prm_fltrLM_R, (end-prm_fltrLM_R+1):end]) = 0;

    % **** Debug code (begin)
    if dbg_on,
        dbg_LMmask(aoi(1):aoi(2), aoi(3):aoi(4)) = ...
            dbg_LMmask(aoi(1):aoi(2), aoi(3):aoi(4)) + ...
            accumaoi_LBMask + 2 * candLM_mask;
    end
    % **** Debug code (end)

    % Group the local maxima candidates by adjacency, compute the
    % centroid position for each group and take that as the center
    % of one circle detected
    [candLM_label, candLM_nRgn] = bwlabel( candLM_mask, 8 );

    for ilabel = 1 : candLM_nRgn,
        % Indices (to current AOI) of the pixels in the group
        candgrp_masklin = find( candLM_label == ilabel );
        [candgrp_IdxI, candgrp_IdxJ] = ...
            ind2sub( size(candLM_label) , candgrp_masklin );

        % Indices (to 'accum') of the pixels in the group
        candgrp_IdxI = candgrp_IdxI + ( aoi(1) - 1 );
        candgrp_IdxJ = candgrp_IdxJ + ( aoi(3) - 1 );
        candgrp_idx2acm = ...
            sub2ind( size(accum) , candgrp_IdxI , candgrp_IdxJ );

        % Minimum number of qulified pixels in the group
        if sum(accumaoi_LBMask(candgrp_masklin)) < prm_fltrLM_npix,
            continue;
        end

        % Compute the centroid position
        candgrp_acmsum = sum( accum(candgrp_idx2acm) );
        cc_x = sum( candgrp_IdxJ .* accum(candgrp_idx2acm) ) / ...
            candgrp_acmsum;
        cc_y = sum( candgrp_IdxI .* accum(candgrp_idx2acm) ) / ...
            candgrp_acmsum;
        circen = [circen; cc_x, cc_y];
    end
end

% **** Debug code (begin)
if dbg_on,
    figure(dbg_bfigno); imagesc(dbg_LMmask); axis image;
    title('Generated map of local maxima');
    if size(accumAOI, 1) == 1,
        figure(dbg_bfigno+1);
        surf(candLM, 'EdgeColor', 'none'); axis ij;
        title('Accumulation array after local maximum filtering');
    end
end
% **** Debug code (end)


%%%%%%%% Estimation of the Radii of Circles %%%%%%%%%%%%

% Stop if no need to estimate the radii of circles
if ~func_compu_radii,
    varargout{1} = circen;
    return;
end

% Parameters for the estimation of the radii of circles
fltr4SgnCv = [2 1 1];
fltr4SgnCv = fltr4SgnCv / sum(fltr4SgnCv);

% Find circle's radius using its signature curve
cirrad = zeros( size(circen,1), 1 );

for k = 1 : size(circen,1),
    % Neighborhood region of the circle for building the sgn. curve
    circen_round = round( circen(k,:) );
    SCvR_I0 = circen_round(2) - prm_r_range(2) - 1;
    if SCvR_I0 < 1,
        SCvR_I0 = 1;
    end
    SCvR_I1 = circen_round(2) + prm_r_range(2) + 1;
    if SCvR_I1 > size(grdx,1),
        SCvR_I1 = size(grdx,1);
    end
    SCvR_J0 = circen_round(1) - prm_r_range(2) - 1;
    if SCvR_J0 < 1,
        SCvR_J0 = 1;
    end
    SCvR_J1 = circen_round(1) + prm_r_range(2) + 1;
    if SCvR_J1 > size(grdx,2),
        SCvR_J1 = size(grdx,2);
    end

    % Build the sgn. curve
    SgnCvMat_dx = repmat( (SCvR_J0:SCvR_J1) - circen(k,1) , ...
        [SCvR_I1 - SCvR_I0 + 1 , 1] );
    SgnCvMat_dy = repmat( (SCvR_I0:SCvR_I1)' - circen(k,2) , ...
        [1 , SCvR_J1 - SCvR_J0 + 1] );
    SgnCvMat_r = sqrt( SgnCvMat_dx .^2 + SgnCvMat_dy .^2 );
    SgnCvMat_rp1 = round(SgnCvMat_r) + 1;

    f4SgnCv = abs( ...
        double(grdx(SCvR_I0:SCvR_I1, SCvR_J0:SCvR_J1)) .* SgnCvMat_dx + ...
        double(grdy(SCvR_I0:SCvR_I1, SCvR_J0:SCvR_J1)) .* SgnCvMat_dy ...
        ) ./ SgnCvMat_r;
    SgnCv = accumarray( SgnCvMat_rp1(:) , f4SgnCv(:) );

    SgnCv_Cnt = accumarray( SgnCvMat_rp1(:) , ones(numel(f4SgnCv),1) );
    SgnCv_Cnt = SgnCv_Cnt + (SgnCv_Cnt == 0);
    SgnCv = SgnCv ./ SgnCv_Cnt;

    % Suppress the undesired entries in the sgn. curve
    % -- Radii that correspond to short arcs
    SgnCv = SgnCv .* ( SgnCv_Cnt >= (pi/4 * [0:(numel(SgnCv_Cnt)-1)]') );
    % -- Radii that are out of the given range
    SgnCv( 1 : (round(prm_r_range(1))+1) ) = 0;
    SgnCv( (round(prm_r_range(2))+1) : end ) = 0;

    % Get rid of the zero radius entry in the array
    SgnCv = SgnCv(2:end);
    % Smooth the sgn. curve
    SgnCv = filtfilt( fltr4SgnCv , [1] , SgnCv );

    % Get the maximum value in the sgn. curve
    SgnCv_max = max(SgnCv);
    if SgnCv_max <= 0,
        cirrad(k) = 0;
        continue;
    end

    % Find the local maxima in sgn. curve by 1st order derivatives
    % -- Mark the ascending edges in the sgn. curve as 1s and
    % -- descending edges as 0s
    SgnCv_AscEdg = ( SgnCv(2:end) - SgnCv(1:(end-1)) ) > 0;
    % -- Mark the transition (ascending to descending) regions
    SgnCv_LMmask = [ 0; 0; SgnCv_AscEdg(1:(end-2)) ] & (~SgnCv_AscEdg);
    SgnCv_LMmask = SgnCv_LMmask & [ SgnCv_LMmask(2:end) ; 0 ];

    % Incorporate the minimum value requirement
    SgnCv_LMmask = SgnCv_LMmask & ...
        ( SgnCv(1:(end-1)) >= (prm_multirad * SgnCv_max) );
    % Get the positions of the peaks
    SgnCv_LMPos = sort( find(SgnCv_LMmask) );

    % Save the detected radii
    if isempty(SgnCv_LMPos),
        cirrad(k) = 0;
    else
        cirrad(k) = SgnCv_LMPos(end);
        for i_radii = (length(SgnCv_LMPos) - 1) : -1 : 1,
            circen = [ circen; circen(k,:) ];
            cirrad = [ cirrad; SgnCv_LMPos(i_radii) ];
        end
    end
end

% Output
varargout{1} = circen;
varargout{2} = cirrad;
if nargout > 3,
    varargout{3} = dbg_LMmask;
end