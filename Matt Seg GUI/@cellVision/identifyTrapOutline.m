function identifyTrapOutline(cCellVision,cTimelapse,trapNum)

%% Identify the trap outline
%This function extracts the outline of the trap by using the timelapse of a
%single tracked trap. It filters the trap using a difference of gaussians,
%and then extracts the edges of the image. The PDMS edges have a more
%pronounced edge and thus it is able to distinguish between the pdms and
%the cells. Doing this throughout the entire timelapse, it then takes the
%median value through time to determine the location of the traps.


if ~isempty(cCellVision.cTrap)
    im=double(cCellVision.cTrap.trap1);
%     im=stdfilt(im);
%     im=imfilter(im,fspecial('disk',2));
%     im=imerode(im,strel('disk',1));
    % im=im-median(im(:));
    %     im=abs(im);
    im=im-min(im(:));
    im=im/max(im(:))*255;
    imflat=zeros([size(im) 2]);
    
    for i=1:2
        
        NumIter = 200; %iterations
        timestep=0.01; %time step
        mu=0.1/timestep;% level set regularization term, please refer to "Chunming Li and et al. Level Set Evolution Without Re-initialization: A New Variational Formulation, CVPR 2005"
        sigma = 3;%size of kernel
        epsilon = 1.5;
        c0 = 4; % the constant value
        lambda1=1.0;%outer weight, please refer to "Chunming Li and et al,  Minimization of Region-Scalable Fitting Energy for Image Segmentation, IEEE Trans. Image Processing, vol. 17 (10), pp. 1940-1949, 2008"
        lambda2=1.3;%inner weight
        %if lambda1>lambda2; tend to inflate
        %if lambda1<lambda2; tend to deflate
        nu = 0.001*255*255;%length term
        alf = 5;%data term weight
        
        h=figure,imagesc(uint8(im),[0 255]),colormap(gray),axis off;axis equal;
        
        [Height Wide] = size(im);
        [xx yy] = meshgrid(1:Wide,1:Height);
        
        if i==1
        fprintf('please select the centre of one of the two traps\n')
        else
            fprintf('please select the ceontre of the other trap\n')
        end
        
        [loc(1) loc(2)]=getpts(gca);
        PntX = loc(1);
        PntY = loc(2);
        
        if false %use the stuff matt originally wrote
            phi = (sqrt(((xx - loc(1)).^2 + (yy - loc(2)).^2 )) - 10);
            phi = sign(phi).*c0;
            close;
            
            
            Ksigma=fspecial('gaussian',round(2*sigma)*2 + 1,sigma); %  kernel
            ONE=ones(size(im));
            KONE = imfilter(ONE,Ksigma,'replicate');
            KI = imfilter(im,Ksigma,'replicate');
            KI2 = imfilter(im.^2,Ksigma,'replicate');
            
            h=figure;
            for iter = 1:NumIter
                phi =evolution_LGD(im,phi,epsilon,Ksigma,KONE,KI,KI2,mu,nu,lambda1,lambda2,timestep,alf);
                if(mod(iter,25) == 0)
                    
                    imagesc(uint8(im),[0 255]),colormap(gray),axis off;axis equal,title(num2str(iter))
                    hold on,[c,h] = contour(phi,[0 0],'r','linewidth',1); hold off
                    pause(0.01);
                end
                
            end
            close;
            c(:,1)=[];
            tempFlat=zeros(size(im));
            
            loc=sub2ind(size(im),floor(c(2,:)),floor(c(1,:)));
            tempFlat(loc)=1;
            imflat(:,:,i)=tempFlat;
        else %use elco's active contour stuff
            ImageTransformParameters = struct('postprocessing','invert');
             ACparameters = struct('alpha',0.01,'beta','0','R_min',3,'R_max',size(im,1)/3,'opt_points',12,...
                'visualise',3,'EVALS',4000,'spread_factor',1,'spread_factor_prior',0.05,'seeds',30,'TerminationEpoch',3000);
            
            ForcingImage = double(cCellVision.cTrap.trap1);
%             ForcingImage=imcomplement(ForcingImage);
            ForcingImage = ForcingImage/median(ForcingImage(:));
            TrapImage = ACBackGroundFunctions.get_cell_image(ForcingImage,min(size(ForcingImage),[],2),[PntX PntY]);
            TrapImage = ACImageTransformations.radial_gradient(TrapImage,ImageTransformParameters);
           
            [RadiiRes,AngleRes] = ACMethods.PSORadialTimeStack(TrapImage,ACparameters,floor(size(TrapImage)/2));
            
            [px,py] = ACBackGroundFunctions.get_full_points_from_radii(RadiiRes',AngleRes',[PntX PntY],size(ForcingImage));
            
            %fudge factor : somewhere in the process the outlines are being
            %shifted by 1. I'm not sure why.
            px = px-1;
            py = py-1;
            
            SegmentationBinary = zeros(size(ForcingImage));
            SegmentationBinary(py+size(ForcingImage,1)*(px-1))=1;
            imflat(:,:,i) = SegmentationBinary;
            
        end
        
    end
    imflat=max(imflat,[],3);
    cCellVision.cTrap.contour=imflat;
    
    imflat=imfill(imflat,'holes');
    imflat=imerode(imflat,strel('disk',1));
    h=figure;imshow(imflat,[]);title('Final Trap Outline');
%     uiwait();
    cCellVision.cTrap.trapOutline=imflat>0;
    
else
    errordlg('There are no traps in this timelapse');
end




function [u ]= evolution_LGD(Img,u,epsilon,Ksigma,KONE,KI,KI2,mu,nu,lambda1,lambda2,timestep,alf)
% This is the evolution step for segmentation using local gaussian distribution (LGD)
% fitting energy
%
% Reference: <Li Wang, Lei He, Arabinda Mishra, Chunming Li.
% Active Contours Driven by Local Gaussian Distribution Fitting Energy.
% Signal Processing, 89(12), 2009,p. 2435-2447>
%
% Please DO NOT distribute this code to anybody.
% Copyright (c) by Li Wang
%
% Author:       Li Wang
% E-mail:       li_wang@med.unc.edu
% URL:          http://www.unc.edu/~liwa/
%
% 2010-01-02 PM


u=NeumannBound(u);
K=curvature_central(u);
H=Heaviside(u,epsilon);
Delta = Dirac(u,epsilon);

KIH = imfilter((H.*Img),Ksigma,'replicate');
KH = imfilter(H,Ksigma,'replicate');
u1= KIH./(KH);
u2 = (KI - KIH)./(KONE - KH);

KI2H = imfilter(Img.^2.*H,Ksigma,'replicate');

sigma1 = (u1.^2.*KH - 2.*u1.*KIH + KI2H)./(KH);
sigma2 = (u2.^2.*KONE - u2.^2.*KH - 2.*u2.*KI + 2.*u2.*KIH + KI2 - KI2H)./(KONE-KH);

sigma1 = sigma1 + eps;
sigma2 = sigma2 + eps;


localForce = (lambda1 - lambda2).*KONE.*log(sqrt(2*pi)) ...
    + imfilter(lambda1.*log(sqrt(sigma1)) - lambda2.*log(sqrt(sigma2)) ...
    +lambda1.*u1.^2./(2.*sigma1) - lambda2.*u2.^2./(2.*sigma2) ,Ksigma,'replicate')...
    + Img.*imfilter(lambda2.*u2./sigma2 - lambda1.*u1./sigma1,Ksigma,'replicate')...
    + Img.^2.*imfilter(lambda1.*1./(2.*sigma1) - lambda2.*1./(2.*sigma2) ,Ksigma,'replicate');

A = -alf.*Delta.*localForce;%data force
P=mu*(4*del2(u) - K);% level set regularization term, please refer to "Chunming Li and et al. Level Set Evolution Without Re-initialization: A New Variational Formulation, CVPR 2005"
L=nu.*Delta.*K;%length term
u = u+timestep*(L+P+A);

return;



function g = NeumannBound(f)
[nrow,ncol] = size(f);
g = f;
g([1 nrow],[1 ncol]) = g([3 nrow-2],[3 ncol-2]);
g([1 nrow],2:end-1) = g([3 nrow-2],2:end-1);
g(2:end-1,[1 ncol]) = g(2:end-1,[3 ncol-2]);


function K = curvature_central(u);
[bdx,bdy]=gradient(u);
mag_bg=sqrt(bdx.^2+bdy.^2)+1e-10;
nx=bdx./mag_bg;
ny=bdy./mag_bg;
[nxx,nxy]=gradient(nx);
[nyx,nyy]=gradient(ny);
K=nxx+nyy;


function h = Heaviside(x,epsilon)
h=0.5*(1+(2/pi)*atan(x./epsilon));

function f = Dirac(x, epsilon)
f=(epsilon/pi)./(epsilon^2.+x.^2);



