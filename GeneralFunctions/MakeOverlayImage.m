function OverlayImage = MakeOverlayImage(Grey,Green,varargin)

Grey = double(Grey);
Grey = 0.5*Grey./max(Grey(:));

Green = double(Green);
Green = 0.5*Green./max(Green(:));

OverlayImage = cat(3,Grey,Grey+Green,Grey);


end