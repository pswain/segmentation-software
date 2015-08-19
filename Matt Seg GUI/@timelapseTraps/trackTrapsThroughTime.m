function trackTrapsThroughTime(cTimelapse,cCellVision,timepoints,isCont)

% isCont is a new true/false in case the segmentation is continuous, so
% don't overwrite the traps

if nargin<3 || isempty(timepoints)
    timepoints=cTimelapse.timepointsToProcess;
end
tic
h = waitbar(0,'Please wait as this tracks the traps through the timelapse ...');

if nargin<4 || isempty(isCont)
    isCont=false;
end

%for initialising trapInfo
if cTimelapse.trapsPresent
    data_template = sparse(false(size(cCellVision.cTrap.trap1)));
else
    data_template = sparse(false(cTimelapse.imSize));
end

trapInfo_struct=struct('segCenters',data_template,'cell',struct('cellCenter',[],'cellRadius',[],'segmented',data_template), ...
    'cellsPresent',0,'cellLabel',[],'segmented',data_template,'trackLabel',data_template);

if cTimelapse.trapsPresent
    
    
    bb=30;
    accumCol=0;
    accumRow=0;
    regIm=cTimelapse.returnSingleTimepoint(timepoints(1));
    regIm=double(regIm);
    regIm=regIm(bb:end-bb,bb:end-bb);
    regImFft=fft2(regIm);
    timepointReg=timepoints(1);
    
        trapInfo_struct(1:length(cTimelapse.cTimepoint(timepoints(1)).trapLocations)) = trapInfo_struct;
    
    for i=2:length(timepoints)
        
        
        
        timepoint=timepoints(i);
        newIm=cTimelapse.returnSingleTimepoint(timepoint);
        cTimelapse.imSize=size(newIm);
        newIm=double(newIm);
        newIm=newIm/median(newIm(:))*median(regIm(:));
        newIm=newIm(bb:end-bb,bb:end-bb);
        %     newIm=padarray(newIm,[bb bb],median(newIm(:)));
        [output ~] = dftregistration(regImFft,fft2(newIm),1);
        %     [output ~] = dftregistration(fft2(regIm),fft2(newIm),1);
        
        
        
        colDif=output(4);
        rowDif=output(3);
        
        %correction for case of huge (innacurate moves)
        if abs(colDif-accumCol)>cTimelapse.cTrapSize.bb_width*1/2
            colDif=accumCol;
        end
        if abs(rowDif-accumRow)>cTimelapse.cTrapSize.bb_height*1/2
            rowDif=accumRow;
        end
        
        accumCol = colDif;
        accumRow = rowDif;
        
        
        xloc=[cTimelapse.cTimepoint(timepointReg).trapLocations(:).xcenter]-colDif;
        yloc=[cTimelapse.cTimepoint(timepointReg).trapLocations(:).ycenter]-rowDif;
        
        xloc(xloc<1) = 1;
        xloc(xloc>cTimelapse.imSize(2)) = cTimelapse.imSize(2);
        yloc(yloc<1) = 1;
        yloc(yloc>cTimelapse.imSize(1)) = cTimelapse.imSize(1);
        
        cTimelapse.cTimepoint(timepoint).trapLocations= cTimelapse.cTimepoint(timepointReg).trapLocations;
        
        xlocCELL=num2cell(xloc);
        ylocCELL = num2cell(yloc);
        
        
        [cTimelapse.cTimepoint(timepoint).trapLocations(:).xcenter]=deal(xlocCELL{:});
        [cTimelapse.cTimepoint(timepoint).trapLocations(:).ycenter]=deal(ylocCELL{:});
        
        if ~isCont
            cTimelapse.cTimepoint(timepoint).trapInfo = trapInfo_struct;
        end
        
        if rem(i,80)==0 || abs(accumRow)>cTimelapse.cTrapSize.bb_height*1/2 || abs(accumCol)>cTimelapse.cTrapSize.bb_width*1/2
            regIm=newIm;
            regImFft=fft2(regIm);
            timepointReg=timepoints(i);
            accumCol = 0;
            accumRow = 0;
        end
        
        waitbar(timepoint/timepoints(end));
        
        %     if rem(timepoint,1e3)==0
        %         regIm=newIm;
        %         accumCol=output(4)+accumCol;
        %         accumRow=output(3)+accumRow;
        %         timepointReg=timepoint;
        %     end
    end
    
else
    [cTimelapse.cTimepoint(timepoints).trapLocations] = deal(struct('xcenter',0,'ycenter',0));
    [cTimelapse.cTimepoint(timepoints).trapInfo] = deal(trapInfo_struct);
    
end

[cTimelapse.cTimepoint(timepoints).trapMaxCell] = deal(zeros(size(cTimelapse.cTimepoint(timepoints(1)).trapLocations)));
[cTimelapse.cTimepoint(timepoints).trapMaxCellUTP] =  deal(zeros(size(cTimelapse.cTimepoint(timepoints(1)).trapLocations)));

toc
close(h)


end
function old2()


%% Identify the same traps throughout time.
%Use the nearestneighbor function and the x and y locations of traps for
%image t and t+1 to track traps throughput time. Because of stage drift,
%there is the possibility that traps could leave the field of view. To
%correct for that check to see if any traps in image t+1 have the same
%label. If so, the trap with the greatest distance measurement must be
%relabeled as numb_traps+1;
if nargin<3 || isempty(timepoints)
    timepoints=1:length(cTimelapse.cTimepoint);
end

h = waitbar(0,'Please wait as this tracks the traps through the timelapse ...');
for i=2:length(timepoints)
    timepoint=timepoints(i);
    cTimelapse.identifyTrapLocationsSingleTP(timepoint,cCellVision,cTimelapse.cTimepoint(timepoints(i-1)).trapLocations);
    waitbar(timepoint/timepoints(end));
    
    xval(1,:)=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).xcenter];
    xval(2,:)=[cTimelapse.cTimepoint(timepoint).trapLocations(:).xcenter];
    yval(1,:)=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).ycenter];
    yval(2,:)=[cTimelapse.cTimepoint(timepoint).trapLocations(:).ycenter];
    xdiff=diff(xval,1,1);
    ydiff=diff(yval,1,1);
    % xdiff=diff(xval,1,1);
    % ydiff=diff(yval,1,1);
    
    [~, ix]=sort(abs(xdiff),'ascend');
    meanDX=mean(xdiff(ix(1:round(length(ix)*.8))),2);
    [~, ix]=sort(abs(ydiff),'ascend');
    meanDY=mean(ydiff(ix(1:round(length(ix)*.8))),2);
    
    xloc=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).xcenter]+meanDX;
    yloc=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).ycenter]+meanDY;
    
    xlocCELL=num2cell(xloc);
    cTimelapse.cTimepoint(timepoint).trapLocations=cTimelapse.cTimepoint(timepoint-1).trapLocations;
    
    [cTimelapse.cTimepoint(timepoint).trapLocations(:).xcenter]=deal(xlocCELL{:});
    ylocCELL = num2cell(yloc);
    [cTimelapse.cTimepoint(timepoint).trapLocations(:).ycenter]=deal(ylocCELL{:});
    
    
end
close(h)

end

function old
xval=[];yval=[];
for i=1:length(timepoints)
    timepoint=timepoints(i);
    xval(timepoint,:)=[cTimelapse.cTimepoint(timepoint).trapLocations(:).xcenter];
    yval(timepoint,:)=[cTimelapse.cTimepoint(timepoint).trapLocations(:).ycenter];
end

% xvalsmooth=[];
% yvalsmooth=[];
% for i=1:size(xval,2)
%     xvalsmooth(:,i)=smooth(xval(:,i),1);
%     yvalsmooth(:,i)=smooth(yval(:,i),1);
% end

xdiff=diff(xval,1,1);
ydiff=diff(yval,1,1);
% xdiff=diff(xval,1,1);
% ydiff=diff(yval,1,1);

meanDX=median(xdiff,2);
meanDY=median(ydiff,2);

for i=2:length(timepoints)
    timepoint=timepoints(i);
    xloc=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).xcenter]+meanDX(timepoint-1);
    yloc=[cTimelapse.cTimepoint(timepoint-1).trapLocations(:).ycenter]+meanDY(timepoint-1);
    
    xlocCELL=num2cell(xloc);
    [cTimelapse.cTimepoint(timepoint).trapLocations(:).xcenter]=deal(xlocCELL{:});
    ylocCELL = num2cell(yloc);
    [cTimelapse.cTimepoint(timepoint).trapLocations(:).ycenter]=deal(ylocCELL{:});
end
end




function [output Greg] = dftregistration(buf1ft,buf2ft,usfac)
% function [output Greg] = dftregistration(buf1ft,buf2ft,usfac);
% Efficient subpixel image registration by crosscorrelation. This code
% gives the same precision as the FFT upsampled cross correlation in a
% small fraction of the computation time and with reduced memory
% requirements. It obtains an initial estimate of the crosscorrelation peak
% by an FFT and then refines the shift estimation by upsampling the DFT
% only in a small neighborhood of that estimate by means of a
% matrix-multiply DFT. With this procedure all the image points are used to
% compute the upsampled crosscorrelation.
% Manuel Guizar - Dec 13, 2007

% Portions of this code were taken from code written by Ann M. Kowalczyk
% and James R. Fienup.
% J.R. Fienup and A.M. Kowalczyk, "Phase retrieval for a complex-valued
% object by using a low-resolution image," J. Opt. Soc. Am. A 7, 450-458
% (1990).

% Citation for this algorithm:
% Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup,
% "Efficient subpixel image registration algorithms," Opt. Lett. 33,
% 156-158 (2008).

% Inputs
% buf1ft    Fourier transform of reference image,
%           DC in (1,1)   [DO NOT FFTSHIFT]
% buf2ft    Fourier transform of image to register,
%           DC in (1,1) [DO NOT FFTSHIFT]
% usfac     Upsampling factor (integer). Images will be registered to
%           within 1/usfac of a pixel. For example usfac = 20 means the
%           images will be registered within 1/20 of a pixel. (default = 1)

% Outputs
% output =  [error,diffphase,net_row_shift,net_col_shift]
% error     Translation invariant normalized RMS error between f and g
% diffphase     Global phase difference between the two images (should be
%               zero if images are non-negative).
% net_row_shift net_col_shift   Pixel shifts between images
% Greg      (Optional) Fourier transform of registered version of buf2ft,
%           the global phase difference is compensated for.

% Default usfac to 1
if exist('usfac')~=1, usfac=1; end

% Compute error for no pixel shift
if usfac == 0,
    CCmax = sum(sum(buf1ft.*conj(buf2ft)));
    rfzero = sum(abs(buf1ft(:)).^2);
    rgzero = sum(abs(buf2ft(:)).^2);
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero*rfzero);
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    output=[error,diffphase];
    
    % Whole-pixel shift - Compute crosscorrelation by an IFFT and locate the
    % peak
elseif usfac == 1,
    [m,n]=size(buf1ft);
    CC = ifft2(buf1ft.*conj(buf2ft));
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);
    cloc=loc2;
    CCmax=CC(rloc,cloc);
    rfzero = sum(abs(buf1ft(:)).^2)/(m*n);
    rgzero = sum(abs(buf2ft(:)).^2)/(m*n);
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero(1,1)*rfzero(1,1));
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    md2 = fix(m/2);
    nd2 = fix(n/2);
    if rloc > md2
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end
    
    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    output=[error,diffphase,row_shift,col_shift];
    
    % Partial-pixel shift
else
    
    % First upsample by a factor of 2 to obtain initial estimate
    % Embed Fourier data in a 2x larger array
    [m,n]=size(buf1ft);
    mlarge=m*2;
    nlarge=n*2;
    CC=zeros(mlarge,nlarge);
    CC(m+1-fix(m/2):m+1+fix((m-1)/2),n+1-fix(n/2):n+1+fix((n-1)/2)) = ...
        fftshift(buf1ft).*conj(fftshift(buf2ft));
    
    % Compute crosscorrelation and locate the peak
    CC = ifft2(ifftshift(CC)); % Calculate cross-correlation
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);cloc=loc2;
    CCmax=CC(rloc,cloc);
    
    % Obtain shift in original pixel grid from the position of the
    % crosscorrelation peak
    [m,n] = size(CC); md2 = fix(m/2); nd2 = fix(n/2);
    if rloc > md2
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end
    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    row_shift=row_shift/2;
    col_shift=col_shift/2;
    
    % If upsampling > 2, then refine estimate with matrix multiply DFT
    if usfac > 2,
        %%% DFT computation %%%
        % Initial shift estimate in upsampled grid
        row_shift = round(row_shift*usfac)/usfac;
        col_shift = round(col_shift*usfac)/usfac;
        dftshift = fix(ceil(usfac*1.5)/2); %% Center of output array at dftshift+1
        % Matrix multiply DFT around the current shift estimate
        CC = conj(dftups(buf2ft.*conj(buf1ft),ceil(usfac*1.5),ceil(usfac*1.5),usfac,...
            dftshift-row_shift*usfac,dftshift-col_shift*usfac))/(md2*nd2*usfac^2);
        % Locate maximum and map back to original pixel grid
        [max1,loc1] = max(CC);
        [max2,loc2] = max(max1);
        rloc = loc1(loc2); cloc = loc2;
        CCmax = CC(rloc,cloc);
        rg00 = dftups(buf1ft.*conj(buf1ft),1,1,usfac)/(md2*nd2*usfac^2);
        rf00 = dftups(buf2ft.*conj(buf2ft),1,1,usfac)/(md2*nd2*usfac^2);
        rloc = rloc - dftshift - 1;
        cloc = cloc - dftshift - 1;
        row_shift = row_shift + rloc/usfac;
        col_shift = col_shift + cloc/usfac;
        
        % If upsampling = 2, no additional pixel shift refinement
    else
        rg00 = sum(sum( buf1ft.*conj(buf1ft) ))/m/n;
        rf00 = sum(sum( buf2ft.*conj(buf2ft) ))/m/n;
    end
    error = 1.0 - CCmax.*conj(CCmax)/(rg00*rf00);
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    % If its only one row or column the shift along that dimension has no
    % effect. We set to zero.
    if md2 == 1,
        row_shift = 0;
    end
    if nd2 == 1,
        col_shift = 0;
    end
    output=[error,diffphase,row_shift,col_shift];
end

% Compute registered version of buf2ft
if (nargout > 1)&&(usfac > 0),
    [nr,nc]=size(buf2ft);
    Nr = ifftshift([-fix(nr/2):ceil(nr/2)-1]);
    Nc = ifftshift([-fix(nc/2):ceil(nc/2)-1]);
    [Nc,Nr] = meshgrid(Nc,Nr);
    Greg = buf2ft.*exp(i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
    Greg = Greg*exp(i*diffphase);
elseif (nargout > 1)&&(usfac == 0)
    Greg = buf2ft*exp(i*diffphase);
end
return
end

function out=dftups(in,nor,noc,usfac,roff,coff)
% function out=dftups(in,nor,noc,usfac,roff,coff);
% Upsampled DFT by matrix multiplies, can compute an upsampled DFT in just
% a small region.
% usfac         Upsampling factor (default usfac = 1)
% [nor,noc]     Number of pixels in the output upsampled DFT, in
%               units of upsampled pixels (default = size(in))
% roff, coff    Row and column offsets, allow to shift the output array to
%               a region of interest on the DFT (default = 0)
% Recieves DC in upper left corner, image center must be in (1,1)
% Manuel Guizar - Dec 13, 2007
% Modified from dftus, by J.R. Fienup 7/31/06

% This code is intended to provide the same result as if the following
% operations were performed
%   - Embed the array "in" in an array that is usfac times larger in each
%     dimension. ifftshift to bring the center of the image to (1,1).
%   - Take the FFT of the larger array
%   - Extract an [nor, noc] region of the result. Starting with the
%     [roff+1 coff+1] element.

% It achieves this result by computing the DFT in the output array without
% the need to zeropad. Much faster and memory efficient than the
% zero-padded FFT approach if [nor noc] are much smaller than [nr*usfac nc*usfac]

[nr,nc]=size(in);
% Set defaults
if exist('roff')~=1, roff=0; end
if exist('coff')~=1, coff=0; end
if exist('usfac')~=1, usfac=1; end
if exist('noc')~=1, noc=nc; end
if exist('nor')~=1, nor=nr; end
% Compute kernels and obtain DFT by matrix products
kernc=exp((-i*2*pi/(nc*usfac))*( ifftshift([0:nc-1]).' - floor(nc/2) )*( [0:noc-1] - coff ));
kernr=exp((-i*2*pi/(nr*usfac))*( [0:nor-1].' - roff )*( ifftshift([0:nr-1]) - floor(nr/2)  ));
out=kernr*in*kernc;
return
end