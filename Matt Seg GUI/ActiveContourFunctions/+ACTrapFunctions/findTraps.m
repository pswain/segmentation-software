function [TrapCentersCell] = findTraps(InputImStack,AllTrapIm,TrapIm)

%InputImStack   -   stack of images in which to find traps
%AllTrapIm      -   image of a field of view with no cells present
%TrapIm         -   an image of a single trap (should be off odd integer size in both dimensions)

%% set thresholds and parameters

%threshold for cross correlation between single Trap image (TrapIm) and
%empty field of view (AllTrapIm)
threshTITI = 0.5;

%% do whole trap image cross correlations
TITIcorr = normxcorr2(TrapIm,padarray(AllTrapIm,size(TrapIm),median(AllTrapIm(:))));
%find central region corresponding to actual image with peaks for traps at
%center.
TITIcorr = TITIcorr((1+floor(1.5*size(TrapIm,1))):(end-floor(1.5*size(TrapIm,1))),(1+floor(1.5*size(TrapIm,2))):(end-floor(1.5*size(TrapIm,2))));

TITIcorrThresh = TITIcorr>threshTITI;
TITIcorr = TITIcorr.*TITIcorrThresh;

%find the limits of the AllTrapIm which are still good trap images (i.e.
%not cut off by the field of view)
[Y,X] = find(TITIcorrThresh);

Xmin = min(X)-floor(size(TrapIm,2)/2);
Ymin = min(Y)-floor(size(TrapIm,1)/2);
Xmax = max(X)+floor(size(TrapIm,2)/2);
Ymax = max(Y)+floor(size(TrapIm,1)/2);


Xmin = max(Xmin,1);
Ymin = max(Ymin,1);
Xmax = min(Xmax,size(InputImStack,2));
Ymax = min(Ymax,size(InputImStack,1));

%make sure differences are odd - more convenient for sorting out reshaping
%after cross correlation and such
if mod(Xmax-Xmin,2)==1 
    Xmin = Xmin+1;
end

if mod(Ymax-Ymin,2)==1 
    Ymin = Ymin+1;
end

%Take only that part of the image with good traps and the corresponding
%part of the cross correlation.
SmallAllTrapIm = AllTrapIm(Ymin:Ymax,Xmin:Xmax);
TITIcorr =  TITIcorr(Ymin:Ymax,Xmin:Xmax);

TrapCentersCell = cell(1,size(InputImStack,3));

for i =1:size(InputImStack,3)
    InputIm = InputImStack(:,:,i);
    %take cross correlation of the remaining all trap image and actual image
    all_trap_corr = normxcorr2(SmallAllTrapIm,InputIm);
    %find central region corresponding to actual image with peaks for traps at
    %center.
    all_trap_corr = all_trap_corr((1+floor(size(SmallAllTrapIm,1)/2)):(end-floor(size(SmallAllTrapIm,1)/2)),(1+floor(size(SmallAllTrapIm,2)/2)):(end-floor(size(SmallAllTrapIm,2)/2)));
    
    all_trap_corr = conv2(double(all_trap_corr==max(all_trap_corr(:))),TITIcorr,'same');
    
    
    %% do single trap correlations
    %take cross correlation of trap image and actual image
    trap_corr = normxcorr2(TrapIm,InputIm);
    %find central region corresponding to actual image with peaks for traps at
    %center.
    trap_corr = trap_corr((1+floor(size(TrapIm,1)/2)):(end-floor(size(TrapIm,1)/2)),(1+floor(size(TrapIm,2)/2)):(end-floor(size(TrapIm,2)/2)));
    
    %% merge single and all trap correlations and convolve with trap pixel image.
    
    TrapCenters = (imregionalmax(trap_corr.*all_trap_corr));
    TrapCentersCell{i} = sparse(TrapCenters);
end
end
