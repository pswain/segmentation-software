im1=cCellVision.cTrap.trap1;
histim=imhist(im1)

figure;imshow(im1);
figure;imshow(histeq(im1))

figure;imshow(histeq(im1))
%%

trapOutline=cCellVision.cTrap.contour;
se1=strel('disk',2);
trapEdge=abs(imerode(trapOutline,se1)-trapOutline);
trapEdge=cCellVision.cTrap.contour;
trapEdge=imdilate(trapEdge,se1);

f1=fspecial('gaussian',11,2);
% f1=imrotate(f1,45);
trapG=imfilter(trapEdge,f1);
% trapG=imfilter(trapG,f1);

trapG=trapG/max(trapG(:));

% trapG=imfilter(trapG,f1);

im1=cTimelapse.returnSingleTrapTimepoint(2,50);
im1=double(im1);

diffIm=im1-median(im1(:));
% diffIm(trapG==0)=0;
diffIm=diffIm.*trapG;
scale=1.5;
imNew=im1-diffIm;

figure(10);imshow(im1,[]);impixelinfo
figure(11);imshow(imNew,[]);impixelinfo

figure(12);imshow(trapG,[]);impixelinfo

figure(13);imshow(diffIm,[]);impixelinfo

%%
temp=[];
for i=1:38
im1=cTimelapse.returnSingleTrapTimepoint(i,3);
im1=double(im1);

[e thresh]=edge(im1,'canny');
[temp(:,:,i) ]=edge(im1,'canny',[.259 .85]);

end
edgeim=sum(temp,3);
figure(123);imshow(edgeim,[])
figure(124);imshow(edgeim>14,[])

bw=edgeim>11;
se1=strel('disk',1);

bw=imclose(bw,se1);
figure(1);imshow(bw,[])

cCellVision.cTrap.contour=double(bwnew);

im1(bw)=im1(bw)*2;
figure(2);imshow(im1,[]);
%%
bw2 = bwmorph(bw,'skel');
figure(3);imshow(bw2,[]);
bwnew=zeros(size(bw2));
bwnew(:,3:end)=bw2(:,1:end-2);
figure(4);imshow(bwnew,[]);

%%


trapEdge=cCellVision.cTrap.contour;

f=fspecial('gaussian',7,1);
f1=f;f1(eye(7)==0)=0;
f2=f;f2(flipud(eye(7))==0)=0;
trapG=imfilter(trapEdge,f1);
% trapG=imfilter(trapG,f1);

im1=cTimelapse.returnSingleTrapTimepoint(2,50);
im1=double(im1);

diffIm=im1-median(im1(:));
diffIm(trapG==0)=0;

scale=.8;
imNew=im1-scale*diffIm;
im_slice=imNew;
    hy = fspecial('sobel'); hx = hy';
    Iy = imfilter(im_slice, hy, 'replicate');
    Ix = imfilter(im_slice, hx, 'replicate');
    im1 = sqrt(Ix.^2 + Iy.^2);
    
figure(10);imshow(im1,[]);
figure(11);imshow(imNew,[]);

figure(12);imshow(trapG,[]);impixelinfo

