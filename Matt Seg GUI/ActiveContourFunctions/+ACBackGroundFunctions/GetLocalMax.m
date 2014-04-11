function LocalMaxCoord = GetLocalMax(SearchCoord,Image,OverlayImage)
%LocalMaxCoord = GetLocalMax(SearchCoord,Image,OverlayImage) find local
%maxima of overlay image centered at SearchCoord (in (y,x) form) dot
%multiplied by overlay image.

Cy = SearchCoord(1);
Cx = SearchCoord(2);

Image = padarray(Image,size(OverlayImage),0);


SearchRangeY = 1:size(OverlayImage,1);
SearchRangeX = 1:size(OverlayImage,2);

SearchEntriesX = Cx + round(size(OverlayImage,2)/2) +SearchRangeX;
SearchEntriesY = Cy + round(size(OverlayImage,1)/2) +SearchRangeY;

SearchRegion = Image(SearchEntriesY,SearchEntriesX);

SearchRegion = SearchRegion.*OverlayImage;

[SearchResultI,SearchResultJ] = find(SearchRegion == max(SearchRegion(:)));

LocalMaxCoordY = SearchEntriesY(SearchResultI) - size(OverlayImage,1);
LocalMaxCoordX = SearchEntriesX(SearchResultJ) - size(OverlayImage,2);

LocalMaxCoord = [LocalMaxCoordY' LocalMaxCoordX'];


end
    