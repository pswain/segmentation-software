function [TITIcorr] = findTrapCrossCorrelation(InputIm,TrapIm)

%InputIm        -   images in which to find traps
%TrapIm         -   an image of a single trap (should be off odd integer size in both dimensions)

%TITIcorr       -   cross correlation

%% do whole trap image cross correlations
TITIcorr = normxcorr2(TrapIm,padarray(InputIm,size(TrapIm),median(InputIm(:))));
%find central region corresponding to actual image with peaks for traps at
%center.
TITIcorr = TITIcorr((1+floor(1.5*size(TrapIm,1))):(end-floor(1.5*size(TrapIm,1))),(1+floor(1.5*size(TrapIm,2))):(end-floor(1.5*size(TrapIm,2))));
end