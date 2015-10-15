function [TITIcorr] = findTrapsSingleImage(InputIm,TrapIm,threshTITI,ExcludeBoolean)

%InputIm        -   images in which to find traps
%TrapIm         -   an image of a single trap (should be off odd integer size in both dimensions)
%threshTITI     -   value at which to threhsold the cross correlation
%                   before doing imregionalmin (default 0.5)
%ExcludeBoolean -   boolean of whether to remove traps within trap each
%                   others trap image (default true).

%TITIcorr       -   an image with the trap centers non zeros (actually a value of their trapishness)
%% set thresholds and parameters

%threshold for cross correlation between single Trap image (TrapIm) and
%the image (InputIm)
if nargin<3
    threshTITI = 0.5;
end

if nargin<4
    ExcludeBoolean = true;
end

%% do whole trap image cross correlations
TITIcorr = normxcorr2(TrapIm,padarray(InputIm,size(TrapIm),median(InputIm(:))));
%find central region corresponding to actual image with peaks for traps at
%center.
TITIcorr = TITIcorr((1+floor(1.5*size(TrapIm,1))):(end-floor(1.5*size(TrapIm,1))),(1+floor(1.5*size(TrapIm,2))):(end-floor(1.5*size(TrapIm,2))));

TITIcorrThresh = TITIcorr>threshTITI;
TITIcorr = TITIcorr.*TITIcorrThresh;
TITIcorr = TITIcorr.*imregionalmax(TITIcorr);

if ExcludeBoolean
    %% if two centers occur within trap image of each other keep only the best
    %one:
    [Centrei,Centrej,Score] = find(TITIcorr);
    
    NumberOfEntries = length(Score);
    
    %Distance of each x coordinate from another in the y direction
    Is = repmat(Centrei,1,NumberOfEntries);
    Is = abs(Is - Is');
    
    %Distance of each x coordinate from another in the x direction
    Js = repmat(Centrej,1,NumberOfEntries);
    Js = abs(Js - Js');
    
    MaxDistance = size(TrapIm)/2;
    
    %entries closer together than the max distance
    TroubleMakers = Is<MaxDistance(1) & Js<MaxDistance(2);
    
    [TroubleMakersi,TroubleMakersj] = find(TroubleMakers);
    
    for TMi = 1:length(TroubleMakersi)
        
        if TroubleMakersi(TMi)>TroubleMakersj(TMi)
            
            if Score(TroubleMakersi(TMi))>Score(TroubleMakersj(TMi))
                
                TITIcorr(Centrei(TroubleMakersj(TMi)),Centrej(TroubleMakersj(TMi))) = 0;
                
            else
                
                
                TITIcorr(Centrei(TroubleMakersi(TMi)),Centrej(TroubleMakersi(TMi))) = 0;
            end
            
        end
        
    end
    
end

end
