image=cTimelapse.returnSingleTrapTimepoint(20,100);
image=double(image);
imMed=median(image(:));

diffIm=(image-imMed);
diffImAbs=abs(diffIm);
diffImAbs=diffImAbs/max(diffImAbs(:));
f1=fspecial('gaussian',5,1);
fIm=imfilter(diffImAbs,f1);
fIm=fIm/max(fIm(:));
newIm=image-(fIm.*diffIm);
figure(2);imshow(newIm,[]);

figure(3);imshow(fIm,[]);impixelinfo
figure(6);imshow(image,[]);

%%

n_filt=5;
nHough=4*1;
nHoughIm=2;
nBW=2*1;
nSym=4;
sim=3
sim*n_filt +(sim*n_filt)*nHough

% filt_feat=(size(im,3)*n_filt)*nHough + (nHoughIm+1)*(size(im,3)*n_filt)*nBW + size(im,3)*n_filt + nSym,'double');

[b ind]=sort(abs(cCellVision.SVMModelLinear.w),'ascend');

sum(abs(cCellVision.SVMModelLinear.w))

bwstart=sim*n_filt +(sim*n_filt)*nHough

bwend=bwstart+(nHoughIm+1)*sim*n_filt*nBW

sum(abs(cCellVision.SVMModelLinear.w(bwstart+1:2:end)))
%%
s=55;
sum(abs(cCellVision.SVMModelLinear.w(s:s+19)))
%%
%%
s=55;
sum(abs(cCellVision.SVMModelLinear.w(1:5)))

